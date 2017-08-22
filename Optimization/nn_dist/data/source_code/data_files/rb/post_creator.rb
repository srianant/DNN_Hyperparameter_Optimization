# Responsible for creating posts and topics
#
require_dependency 'rate_limiter'
require_dependency 'topic_creator'
require_dependency 'post_jobs_enqueuer'
require_dependency 'distributed_mutex'
require_dependency 'has_errors'

class PostCreator
  include HasErrors

  attr_reader :opts

  # Acceptable options:
  #
  #   raw                     - raw text of post
  #   image_sizes             - We can pass a list of the sizes of images in the post as a shortcut.
  #   invalidate_oneboxes     - Whether to force invalidation of oneboxes in this post
  #   acting_user             - The user performing the action might be different than the user
  #                             who is the post "author." For example when copying posts to a new
  #                             topic.
  #   created_at              - Post creation time (optional)
  #   auto_track              - Automatically track this topic if needed (default true)
  #   custom_fields           - Custom fields to be added to the post, Hash (default nil)
  #   post_type               - Whether this is a regular post or moderator post.
  #   no_bump                 - Do not cause this post to bump the topic.
  #   cooking_options         - Options for rendering the text
  #   cook_method             - Method of cooking the post.
  #                               :regular - Pass through Markdown parser and strip bad HTML
  #                               :raw_html - Perform no processing
  #                               :raw_email - Imported from an email
  #   via_email               - Mark this post as arriving via email
  #   raw_email               - Full text of arriving email (to store)
  #   action_code             - Describes a small_action post (optional)
  #   skip_jobs               - Don't enqueue jobs when creation succeeds. This is needed if you
  #                             wrap `PostCreator` in a transaction, as the sidekiq jobs could
  #                             dequeue before the commit finishes. If you do this, be sure to
  #                             call `enqueue_jobs` after the transaction is comitted.
  #
  #   When replying to a topic:
  #     topic_id              - topic we're replying to
  #     reply_to_post_number  - post number we're replying to
  #
  #   When creating a topic:
  #     title                 - New topic title
  #     archetype             - Topic archetype
  #     is_warning            - Is the topic a warning?
  #     category              - Category to assign to topic
  #     target_usernames      - comma delimited list of usernames for membership (private message)
  #     target_group_names    - comma delimited list of groups for membership (private message)
  #     meta_data             - Topic meta data hash
  #     created_at            - Topic creation time (optional)
  #     pinned_at             - Topic pinned time (optional)
  #     pinned_globally       - Is the topic pinned globally (optional)
  #
  def initialize(user, opts)
    # TODO: we should reload user in case it is tainted, should take in a user_id as opposed to user
    # If we don't do this we introduce a rather risky dependency
    @user = user
    @opts = opts || {}
    opts[:title] = pg_clean_up(opts[:title]) if opts[:title] && opts[:title].include?("\u0000")
    opts[:raw] = pg_clean_up(opts[:raw]) if opts[:raw] && opts[:raw].include?("\u0000")
    opts.delete(:reply_to_post_number) unless opts[:topic_id]
    @guardian = opts[:guardian] if opts[:guardian]

    @spam = false
  end

  def pg_clean_up(str)
    str.gsub("\u0000", "")
  end

  # True if the post was considered spam
  def spam?
    @spam
  end

  def skip_validations?
    @opts[:skip_validations]
  end

  def guardian
    @guardian ||= Guardian.new(@user)
  end

  def valid?
    @topic = nil
    @post = nil

    if @user.suspended? && !skip_validations?
      errors[:base] << I18n.t(:user_is_suspended)
      return false
    end

    if new_topic?
      topic_creator = TopicCreator.new(@user, guardian, @opts)
      return false unless skip_validations? || validate_child(topic_creator)
    else
      @topic = Topic.find_by(id: @opts[:topic_id])
      if (@topic.blank? || !guardian.can_create?(Post, @topic))
        errors[:base] << I18n.t(:topic_not_found)
        return false
      end
    end

    setup_post

    return true if skip_validations?

    if @post.has_host_spam?
      @spam = true
      errors[:base] << I18n.t(:spamming_host)
      return false
    end

    DiscourseEvent.trigger :before_create_post, @post
    DiscourseEvent.trigger :validate_post, @post

    post_validator = Validators::PostValidator.new(skip_topic: true)
    post_validator.validate(@post)

    valid = @post.errors.blank?
    add_errors_from(@post) unless valid
    valid
  end

  def create
    if valid?
      transaction do
        build_post_stats
        create_topic
        save_post
        extract_links
        store_unique_post_key
        track_topic
        update_topic_stats
        update_topic_auto_close
        update_user_counts
        create_embedded_topic

        ensure_in_allowed_users if guardian.is_staff?
        unarchive_message
        @post.advance_draft_sequence
        @post.save_reply_relationships
      end
    end

    if @post && errors.blank?
      publish

      track_latest_on_category
      enqueue_jobs unless @opts[:skip_jobs]
      BadgeGranter.queue_badge_grant(Badge::Trigger::PostRevision, post: @post)

      trigger_after_events(@post)

      auto_close unless @opts[:import_mode]
    end

    if @post || @spam
      handle_spam unless @opts[:import_mode]
    end

    @post
  end

  def create!
    create

    if !self.errors.full_messages.empty?
      raise ActiveRecord::RecordNotSaved.new("Failed to create post", self)
    end

    @post
  end

  def enqueue_jobs
    return unless @post && !@post.errors.present?
    PostJobsEnqueuer.new(@post, @topic, new_topic?, {import_mode: @opts[:import_mode]}).enqueue_jobs
  end

  def self.track_post_stats
    Rails.env != "test".freeze || @track_post_stats
  end

  def self.track_post_stats=(val)
    @track_post_stats = val
  end

  def self.create(user, opts)
    PostCreator.new(user, opts).create
  end

  def self.create!(user, opts)
    PostCreator.new(user, opts).create!
  end

  def self.before_create_tasks(post)
    set_reply_info(post)

    post.word_count = post.raw.scan(/[[:word:]]+/).size
    post.post_number ||= Topic.next_post_number(post.topic_id, post.reply_to_post_number.present?)

    cooking_options = post.cooking_options || {}
    cooking_options[:topic_id] = post.topic_id

    post.cooked ||= post.cook(post.raw, cooking_options.symbolize_keys)
    post.sort_order = post.post_number
    post.last_version_at ||= Time.now
  end

  def self.set_reply_info(post)
    return unless post.reply_to_post_number.present?

    reply_info = Post.where(topic_id: post.topic_id, post_number: post.reply_to_post_number)
                     .select(:user_id, :post_type)
                     .first

    if reply_info.present?
      post.reply_to_user_id ||= reply_info.user_id
      whisper_type = Post.types[:whisper]
      post.post_type = whisper_type if reply_info.post_type == whisper_type
    end
  end

  protected

  def build_post_stats
    if PostCreator.track_post_stats
      draft_key = @topic ? "topic_#{@topic.id}" : "new_topic"

      sequence = DraftSequence.current(@user, draft_key)
      revisions = Draft.where(sequence: sequence,
                              user_id: @user.id,
                              draft_key: draft_key).pluck(:revisions).first || 0

      @post.build_post_stat(
        drafts_saved: revisions,
        typing_duration_msecs: @opts[:typing_duration_msecs] || 0,
        composer_open_duration_msecs: @opts[:composer_open_duration_msecs] || 0
      )
    end
  end

  def trigger_after_events(post)
    DiscourseEvent.trigger(:topic_created, post.topic, @opts, @user) unless @opts[:topic_id]
    DiscourseEvent.trigger(:post_created, post, @opts, @user)
  end

  def auto_close
    if @post.topic.private_message? &&
        !@post.topic.closed &&
        SiteSetting.auto_close_messages_post_count > 0 &&
        SiteSetting.auto_close_messages_post_count <= @post.topic.posts_count

      @post.topic.update_status(:closed, true, Discourse.system_user,
          message: I18n.t('topic_statuses.autoclosed_message_max_posts', count: SiteSetting.auto_close_messages_post_count))

    elsif !@post.topic.private_message? &&
        !@post.topic.closed &&
        SiteSetting.auto_close_topics_post_count > 0 &&
        SiteSetting.auto_close_topics_post_count <= @post.topic.posts_count

      @post.topic.update_status(:closed, true, Discourse.system_user,
          message: I18n.t('topic_statuses.autoclosed_topic_max_posts', count: SiteSetting.auto_close_topics_post_count))

    end
  end

  def transaction(&blk)
    Post.transaction do
      if new_topic?
        blk.call
      else
        # we need to ensure post_number is monotonically increasing with no gaps
        # so we serialize creation to avoid needing rollbacks
        DistributedMutex.synchronize("topic_id_#{@opts[:topic_id]}", &blk)
      end
    end
  end

  # You can supply an `embed_url` for a post to set up the embedded relationship.
  # This is used by the wp-discourse plugin to associate a remote post with a
  # discourse post.
  def create_embedded_topic
    return unless @opts[:embed_url].present?
    embed = TopicEmbed.new(topic_id: @post.topic_id, post_id: @post.id, embed_url: @opts[:embed_url])
    rollback_from_errors!(embed) unless embed.save
  end

  def handle_spam
    if @spam
      GroupMessage.create( Group[:moderators].name,
                           :spam_post_blocked,
                           { user: @user,
                             limit_once_per: 24.hours,
                             message_params: {domains: @post.linked_hosts.keys.join(', ')} } )
    elsif @post && errors.blank? && !skip_validations?
      SpamRulesEnforcer.enforce!(@post)
    end
  end

  def track_latest_on_category
    return unless @post && @post.errors.count == 0 && @topic && @topic.category_id

    Category.where(id: @topic.category_id).update_all(latest_post_id: @post.id)
    Category.where(id: @topic.category_id).update_all(latest_topic_id: @topic.id) if @post.is_first_post?
  end

  def ensure_in_allowed_users
    return unless @topic.private_message? && @topic.id

    unless @topic.topic_allowed_users.where(user_id: @user.id).exists?
      unless @topic.topic_allowed_groups.where('group_id IN (
                                              SELECT group_id FROM group_users where user_id = ?
                                           )',@user.id).exists?
        @topic.topic_allowed_users.create!(user_id: @user.id)
      end
    end
  end

  def unarchive_message
    return unless @topic.private_message? && @topic.id

    UserArchivedMessage.where(topic_id: @topic.id).pluck(:user_id).each do |user_id|
      UserArchivedMessage.move_to_inbox!(user_id, @topic.id)
    end

    GroupArchivedMessage.where(topic_id: @topic.id).pluck(:group_id).each do |group_id|
      GroupArchivedMessage.move_to_inbox!(group_id, @topic.id)
    end
  end

  private

  def create_topic
    return if @topic
    begin
      topic_creator = TopicCreator.new(@user, guardian, @opts)
      @topic = topic_creator.create
    rescue ActiveRecord::Rollback
      rollback_from_errors!(topic_creator)
    end
    @post.topic_id = @topic.id
    @post.topic = @topic
  end

  def update_topic_stats
    return if @post.post_type == Post.types[:whisper]

    attrs = {
      last_posted_at: @post.created_at,
      last_post_user_id: @post.user_id,
      word_count: (@topic.word_count || 0) + @post.word_count,
    }
    attrs[:excerpt] = @post.excerpt(220, strip_links: true) if new_topic?
    attrs[:bumped_at] = @post.created_at unless @post.no_bump
    @topic.update_attributes(attrs)
  end

  def update_topic_auto_close
    if @topic.auto_close_based_on_last_post && @topic.auto_close_hours
      @topic.set_auto_close(@topic.auto_close_hours).save
    end
  end

  def setup_post
    @opts[:raw] = TextCleaner.normalize_whitespaces(@opts[:raw] || '').gsub(/\s+\z/, "")

    post = Post.new(raw: @opts[:raw],
                    topic_id: @topic.try(:id),
                    user: @user,
                    reply_to_post_number: @opts[:reply_to_post_number])

    # Attributes we pass through to the post instance if present
    [:post_type, :no_bump, :cooking_options, :image_sizes, :acting_user, :invalidate_oneboxes, :cook_method, :via_email, :raw_email, :action_code].each do |a|
      post.send("#{a}=", @opts[a]) if @opts[a].present?
    end

    post.extract_quoted_post_numbers
    post.created_at = Time.zone.parse(@opts[:created_at].to_s) if @opts[:created_at].present?

    if fields = @opts[:custom_fields]
      post.custom_fields = fields
    end

    @post = post
  end

  def save_post
    @post.disable_rate_limits! if skip_validations?
    saved = @post.save(validate: !skip_validations?)
    rollback_from_errors!(@post) unless saved
  end

  def store_unique_post_key
    @post.store_unique_post_key
  end

  def update_user_counts
    return if @opts[:import_mode]

    @user.create_user_stat if @user.user_stat.nil?

    if @user.user_stat.first_post_created_at.nil?
      @user.user_stat.first_post_created_at = @post.created_at
    end

    unless @post.topic.private_message?
      @user.user_stat.post_count += 1
      @user.user_stat.topic_count += 1 if @post.is_first_post?
    end

    # We don't count replies to your own topics
    if !@opts[:import_mode] && @user.id != @topic.user_id
      @user.user_stat.update_topic_reply_count
    end

    @user.user_stat.save!

    @user.update_attributes(last_posted_at: @post.created_at)
  end

  def publish
    return if @opts[:import_mode]
    return unless @post.post_number > 1

    @post.publish_change_to_clients! :created
  end

  def extract_links
    TopicLink.extract_from(@post)
    QuotedPost.extract_from(@post)
  end

  def track_topic
    return if @opts[:auto_track] == false

    unless @user.user_option.disable_jump_reply?
      TopicUser.change(@post.user_id,
                       @topic.id,
                       posted: true,
                       last_read_post_number: @post.post_number,
                       highest_seen_post_number: @post.post_number)


      # assume it took us 5 seconds of reading time to make a post
      PostTiming.record_timing(topic_id: @post.topic_id,
                               user_id: @post.user_id,
                               post_number: @post.post_number,
                               msecs: 5000)
    end

    if @user.staged
      TopicUser.auto_notification_for_staging(@user.id, @topic.id, TopicUser.notification_reasons[:auto_watch])
    elsif @user.user_option.notification_level_when_replying === NotificationLevels.topic_levels[:watching]
      TopicUser.auto_notification(@user.id, @topic.id, TopicUser.notification_reasons[:created_post], NotificationLevels.topic_levels[:watching])
    else
      TopicUser.auto_notification(@user.id, @topic.id, TopicUser.notification_reasons[:created_post], NotificationLevels.topic_levels[:tracking])
    end
  end

  def new_topic?
    @opts[:topic_id].blank?
  end

end
