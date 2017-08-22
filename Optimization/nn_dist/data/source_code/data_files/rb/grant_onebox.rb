module Jobs

  class GrantOnebox < Jobs::Onceoff
    sidekiq_options queue: 'low'

    def execute_onceoff(args)
      return unless SiteSetting.enable_badges
      to_award = {}

      Post.secured(Guardian.new)
          .select(:id, :created_at, :raw, :user_id)
          .visible
          .public_posts
          .where("raw LIKE '%http%'")
          .find_in_batches do |group|
        group.each do |p|
          begin
            # Note we can't use `p.cooked` here because oneboxes have been cooked out
            cooked = PrettyText.cook(p.raw)
            doc = Nokogiri::HTML::fragment(cooked)
            if doc.search('a.onebox').size > 0
              to_award[p.user_id] ||= { post_id: p.id, created_at: p.created_at }
            end
          rescue
            nil # if there is a problem cooking we don't care
          end
        end

      end

      to_award.each do |user_id, opts|
        user = User.where(id: user_id).first
        BadgeGranter.grant(badge, user, opts) if user
      end
    end

    def badge
      @badge ||= Badge.find(Badge::FirstOnebox)
    end

  end

end
