require_dependency 'pinned_check'

class CategoryList
  include ActiveModel::Serialization

  attr_accessor :categories,
                :uncategorized,
                :draft,
                :draft_key,
                :draft_sequence

  def initialize(guardian=nil, options={})
    @guardian = guardian || Guardian.new
    @options = options

    find_relevant_topics if options[:include_topics]
    find_categories

    prune_empty
    find_user_data
    sort_unpinned
    trim_results
  end

  def preload_key
    "categories_list".freeze
  end

  private

    def find_relevant_topics
      @topics_by_id = {}
      @topics_by_category_id = {}

      category_featured_topics = CategoryFeaturedTopic.select([:category_id, :topic_id]).order(:rank)

      @all_topics = Topic.where(id: category_featured_topics.map(&:topic_id))
      @all_topics = @all_topics.includes(:last_poster) if @options[:include_topics]
      @all_topics.each do |t|
        # hint for the serializer
        t.include_last_poster = true if @options[:include_topics]
        @topics_by_id[t.id] = t
      end

      category_featured_topics.each do |cft|
        @topics_by_category_id[cft.category_id] ||= []
        @topics_by_category_id[cft.category_id] << cft.topic_id
      end
    end

    def find_categories
      @categories = Category.includes(:topic_only_relative_url, subcategories: [:topic_only_relative_url]).secured(@guardian)
      @categories = @categories.where(suppress_from_homepage: false) if @options[:is_homepage]
      @categories = @categories.where("categories.parent_category_id = ?", @options[:parent_category_id].to_i) if @options[:parent_category_id].present?

      if SiteSetting.fixed_category_positions
        @categories = @categories.order(:position, :id)
      else
        @categories = @categories.order('COALESCE(categories.posts_week, 0) DESC')
                                 .order('COALESCE(categories.posts_month, 0) DESC')
                                 .order('COALESCE(categories.posts_year, 0) DESC')
                                 .order('id ASC')
      end

      @categories = @categories.to_a

      category_user = {}
      unless @guardian.anonymous?
        category_user = Hash[*CategoryUser.where(user: @guardian.user).pluck(:category_id, :notification_level).flatten]
      end

      allowed_topic_create = Set.new(Category.topic_create_allowed(@guardian).pluck(:id))
      @categories.each do |category|
        category.notification_level = category_user[category.id]
        category.permission = CategoryGroup.permission_types[:full] if allowed_topic_create.include?(category.id)
        category.has_children = category.subcategories.present?
      end

      if @options[:parent_category_id].blank?
        subcategories = {}
        to_delete = Set.new
        @categories.each do |c|
          if c.parent_category_id.present?
            subcategories[c.parent_category_id] ||= []
            subcategories[c.parent_category_id] << c.id
            to_delete << c
          end
        end
        @categories.each { |c| c.subcategory_ids = subcategories[c.id] }
        @categories.delete_if { |c| to_delete.include?(c) }
      end

      if @topics_by_category_id
        @categories.each do |c|
          topics_in_cat = @topics_by_category_id[c.id]
          if topics_in_cat.present?
            c.displayable_topics = []
            topics_in_cat.each do |topic_id|
              topic = @topics_by_id[topic_id]
              if topic.present? && @guardian.can_see?(topic)
                # topic.category is very slow under rails 4.2
                topic.association(:category).target = c
                c.displayable_topics << topic
              end
            end
          end
        end
      end
    end

    def prune_empty
      return if SiteSetting.allow_uncategorized_topics
      @categories.delete_if { |c| c.uncategorized? && c.displayable_topics.blank? }
    end

    # Attach some data for serialization to each topic
    def find_user_data
      if @guardian.current_user && @all_topics.present?
        topic_lookup = TopicUser.lookup_for(@guardian.current_user, @all_topics)
        @all_topics.each { |ft| ft.user_data = topic_lookup[ft.id] }
      end
    end

    # Put unpinned topics at the end of the list
    def sort_unpinned
      if @guardian.current_user && @all_topics.present?
        @categories.each do |c|
          next if c.displayable_topics.blank? || c.displayable_topics.size <= SiteSetting.category_featured_topics
          unpinned = []
          c.displayable_topics.each do |t|
            unpinned << t if t.pinned_at && PinnedCheck.unpinned?(t, t.user_data)
          end
          unless unpinned.empty?
            c.displayable_topics = (c.displayable_topics - unpinned) + unpinned
          end
        end
      end
    end

    def trim_results
      @categories.each do |c|
        next if c.displayable_topics.blank?
        c.displayable_topics = c.displayable_topics[0, SiteSetting.category_featured_topics]
      end
    end

end
