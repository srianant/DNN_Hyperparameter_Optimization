module Jobs

  class NotifyMailingListSubscribers < Jobs::Base

    sidekiq_options queue: 'low'

    def execute(args)
      return if SiteSetting.disable_mailing_list_mode

      post_id = args[:post_id]
      post = post_id ? Post.with_deleted.find_by(id: post_id) : nil

      raise Discourse::InvalidParameters.new(:post_id) unless post
      return if post.trashed? || post.user_deleted? || (!post.topic)

      users =
          User.activated.not_blocked.not_suspended.real
          .joins(:user_option)
          .where('user_options.mailing_list_mode AND user_options.mailing_list_mode_frequency > 0')
          .where('NOT EXISTS(
                      SELECT 1
                      FROM topic_users tu
                      WHERE
                        tu.topic_id = ? AND
                        tu.user_id = users.id AND
                        tu.notification_level = ?
                  )', post.topic_id, TopicUser.notification_levels[:muted])
          .where('NOT EXISTS(
                     SELECT 1
                     FROM category_users cu
                     WHERE
                       cu.category_id = ? AND
                       cu.user_id = users.id AND
                       cu.notification_level = ?
                  )', post.topic.category_id, CategoryUser.notification_levels[:muted])

      users.each do |user|
        if Guardian.new(user).can_see?(post)
          if EmailLog.reached_max_emails?(user)
            skip(user.email, user.id, post.id, I18n.t('email_log.exceeded_emails_limit'))
            next
          end

          if user.user_stat.bounce_score >= SiteSetting.bounce_score_threshold
            skip(user.email, user.id, post.id, I18n.t('email_log.exceeded_bounces_limit'))
            next
          end

          if (user.id == post.user_id) && (user.user_option.mailing_list_mode_frequency == 2)
            skip(user.email, user.id, post.id, I18n.t('email_log.no_echo_mailing_list_mode'))
            next
          end

          begin
            if message = UserNotifications.mailing_list_notify(user, post)
              EmailLog.unique_email_per_post(post, user) do
                Email::Sender.new(message, :mailing_list, user).send
              end
            end
          rescue => e
            Discourse.handle_job_exception(e, error_context(args, "Sending post to mailing list subscribers", { user_id: user.id, user_email: user.email }))
          end
        end
      end

    end

    def skip(to_address, user_id, post_id, reason)
      EmailLog.create!(
        email_type: 'mailing_list',
        to_address: to_address,
        user_id: user_id,
        post_id: post_id,
        skipped: true,
        skipped_reason: "[MailingList] #{reason}"
      )
    end
  end
end
