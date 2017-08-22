require 'uri'
require_dependency 'slug'

class TopicLink < ActiveRecord::Base

  def self.max_domain_length
    100
  end

  def self.max_url_length
    500
  end

  belongs_to :topic
  belongs_to :user
  belongs_to :post
  belongs_to :link_topic, class_name: 'Topic'
  belongs_to :link_post, class_name: 'Post'

  validates_presence_of :url

  validates_length_of :url, maximum: 500

  validates_uniqueness_of :url, scope: [:topic_id, :post_id]

  has_many :topic_link_clicks, dependent: :destroy

  validate :link_to_self

  after_commit :crawl_link_title

  # Make sure a topic can't link to itself
  def link_to_self
    errors.add(:base, "can't link to the same topic") if (topic_id == link_topic_id)
  end

  def self.topic_map(guardian, topic_id)

    # Sam: complicated reports are really hard in AR
    builder = SqlBuilder.new <<SQL
  SELECT ftl.url,
         COALESCE(ft.title, ftl.title) AS title,
         ftl.link_topic_id,
         ftl.reflection,
         ftl.internal,
         ftl.domain,
         MIN(ftl.user_id) AS user_id,
         SUM(clicks) AS clicks
  FROM topic_links AS ftl
  LEFT JOIN topics AS ft ON ftl.link_topic_id = ft.id
  LEFT JOIN categories AS c ON c.id = ft.category_id
  /*where*/
  GROUP BY ftl.url, ft.title, ftl.title, ftl.link_topic_id, ftl.reflection, ftl.internal, ftl.domain
  ORDER BY clicks DESC, count(*) DESC
  LIMIT 50
SQL

    builder.where('ftl.topic_id = :topic_id', topic_id: topic_id)
    builder.where('ft.deleted_at IS NULL')
    builder.where("COALESCE(ft.archetype, 'regular') <> :archetype", archetype: Archetype.private_message)

    builder.secure_category(guardian.secure_category_ids)

    builder.exec.to_a

  end

  def self.counts_for(guardian,topic, posts)
    return {} if posts.blank?

    # Sam: I don't know how to write this cleanly in AR,
    #   in particular the securing logic is tricky and would fallback to SQL anyway
    builder = SqlBuilder.new("SELECT
                      l.post_id,
                      l.url,
                      l.clicks,
                      COALESCE(t.title, l.title) AS title,
                      l.internal,
                      l.reflection,
                      l.domain
              FROM topic_links l
              LEFT JOIN topics t ON t.id = l.link_topic_id
              LEFT JOIN categories AS c ON c.id = t.category_id
              /*where*/
              ORDER BY reflection ASC, clicks DESC")

    builder.where('t.deleted_at IS NULL')
    builder.where("COALESCE(t.archetype, 'regular') <> :archetype", archetype: Archetype.private_message)

    # not certain if pluck is right, cause it may interfere with caching
    builder.where('l.post_id IN (:post_ids)', post_ids: posts.map(&:id))
    builder.secure_category(guardian.secure_category_ids)

    builder.map_exec(OpenStruct).each_with_object({}) do |l,result|
      result[l.post_id] ||= []
      result[l.post_id] << {url: l.url,
                            clicks: l.clicks,
                            title: l.title,
                            internal: l.internal,
                            reflection: l.reflection}
    end
  end

  # Extract any urls in body
  def self.extract_from(post)
    return unless post.present?

    added_urls = []
    TopicLink.transaction do

      added_urls = []
      reflected_ids = []

      PrettyText
        .extract_links(post.cooked)
        .map { |u| [u, URI.parse(u.url)] rescue nil }
        .reject { |_, p| p.nil? || "mailto".freeze == p.scheme }
        .uniq { |_, p| p }
        .each do |link, parsed|
        begin
          url = link.url
          internal = false
          topic_id = nil
          post_number = nil
          parsed_path = parsed.path || ""

          if Discourse.store.has_been_uploaded?(url)
            internal = Discourse.store.internal?
          elsif (parsed.host == Discourse.current_hostname && parsed_path.start_with?(Discourse.base_uri)) || !parsed.host
            internal = true

            parsed_path.slice!(Discourse.base_uri)

            route = Rails.application.routes.recognize_path(parsed_path)

            # We aren't interested in tracking internal links to users
            next if route[:controller] == 'users'

            topic_id = route[:topic_id].to_i
            post_number = route[:post_number] || 1

            # Store the canonical URL
            topic = Topic.find_by(id: topic_id)
            topic_id = nil unless topic

            if topic.present?
              url = "#{Discourse.base_url_no_prefix}#{topic.relative_url}"
              url << "/#{post_number}" if post_number.to_i > 1
            end

          end

          # Skip linking to ourselves
          next if topic_id == post.topic_id

          reflected_post = nil
          if post_number && topic_id
            reflected_post = Post.find_by(topic_id: topic_id, post_number: post_number.to_i)
          end

          url = url[0...TopicLink.max_url_length]
          next if parsed && parsed.host && parsed.host.length > TopicLink.max_domain_length

          added_urls << url

          topic_link = TopicLink.find_by(topic_id: post.topic_id,
                                         post_id: post.id,
                                         url: url)

          unless topic_link
            TopicLink.create!(post_id: post.id,
                              user_id: post.user_id,
                              topic_id: post.topic_id,
                              url: url,
                              domain: parsed.host || Discourse.current_hostname,
                              internal: internal,
                              link_topic_id: topic_id,
                              link_post_id: reflected_post.try(:id),
                              quote: link.is_quote)
          end

          # Create the reflection if we can
          if topic_id.present?
            topic = Topic.find_by(id: topic_id)

            if topic && post.topic && post.topic.archetype != 'private_message' && topic.archetype != 'private_message'

              prefix = Discourse.base_url_no_prefix

              reflected_url = "#{prefix}#{post.topic.relative_url(post.post_number)}"

              tl = TopicLink.find_by(topic_id: topic_id,
                                     post_id: reflected_post.try(:id),
                                     url: reflected_url)

              unless tl
                tl = TopicLink.create!(user_id: post.user_id,
                                    topic_id: topic_id,
                                    post_id: reflected_post.try(:id),
                                    url: reflected_url,
                                    domain: Discourse.current_hostname,
                                    reflection: true,
                                    internal: true,
                                    link_topic_id: post.topic_id,
                                    link_post_id: post.id)

              end

              reflected_ids << tl.try(:id)
            end
          end

        rescue URI::InvalidURIError
          # if the URI is invalid, don't store it.
        rescue ActionController::RoutingError
          # If we can't find the route, no big deal
        end
      end

      # Remove links that aren't there anymore
      if added_urls.present?
        TopicLink.delete_all ["(url not in (:urls)) AND (post_id = :post_id AND NOT reflection)", urls: added_urls, post_id: post.id]

        reflected_ids.compact!
        if reflected_ids.present?
          TopicLink.delete_all ["(id not in (:reflected_ids)) AND (link_post_id = :post_id AND reflection)",
                                reflected_ids: reflected_ids, post_id: post.id]
        else
          TopicLink.delete_all ["link_post_id = :post_id AND reflection", post_id: post.id]
        end
      else
        TopicLink.delete_all ["(post_id = :post_id AND NOT reflection) OR (link_post_id = :post_id AND reflection)", post_id: post.id]
      end
    end
  end

  # Crawl a link's title after it's saved
  def crawl_link_title
    Jobs.enqueue(:crawl_topic_link, topic_link_id: id)
  end

  def self.duplicate_lookup(topic)
    results = TopicLink
                .includes(:post, :user)
                .joins(:post, :user)
                .where("posts.id IS NOT NULL AND users.id IS NOT NULL")
                .where(topic_id: topic.id, reflection: false)
                .last(200)

    lookup = {}
    results.each do |tl|
      normalized = tl.url.downcase.sub(/^https?:\/\//, '').sub(/\/$/, '')
      lookup[normalized] = { domain: tl.domain,
                             username: tl.user.username_lower,
                             posted_at: tl.post.created_at,
                             post_number: tl.post.post_number }
    end

    lookup
  end
end

# == Schema Information
#
# Table name: topic_links
#
#  id            :integer          not null, primary key
#  topic_id      :integer          not null
#  post_id       :integer
#  user_id       :integer          not null
#  url           :string(500)      not null
#  domain        :string(100)      not null
#  internal      :boolean          default(FALSE), not null
#  link_topic_id :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  reflection    :boolean          default(FALSE)
#  clicks        :integer          default(0), not null
#  link_post_id  :integer
#  title         :string
#  crawled_at    :datetime
#  quote         :boolean          default(FALSE), not null
#
# Indexes
#
#  index_topic_links_on_link_post_id_and_reflection  (link_post_id,reflection)
#  index_topic_links_on_post_id                      (post_id)
#  index_topic_links_on_topic_id                     (topic_id)
#  unique_post_links                                 (topic_id,post_id,url) UNIQUE
#
