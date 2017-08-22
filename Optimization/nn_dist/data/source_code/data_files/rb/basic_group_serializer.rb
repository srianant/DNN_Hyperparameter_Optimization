class BasicGroupSerializer < ApplicationSerializer
  attributes :id,
             :automatic,
             :name,
             :user_count,
             :alias_level,
             :visible,
             :automatic_membership_email_domains,
             :automatic_membership_retroactive,
             :primary_group,
             :title,
             :grant_trust_level,
             :incoming_email,
             :notification_level,
             :has_messages,
             :is_member,
             :mentionable,
             :flair_url,
             :flair_bg_color,
             :flair_color

  def include_incoming_email?
    scope.is_staff?
  end

  def notification_level
    # TODO: fix this N+1
    GroupUser.where(group_id: object.id, user_id: scope.user.id).first.try(:notification_level)
  end

  def include_notification_level?
    scope.authenticated?
  end

  def mentionable
    object.mentionable?(scope.user, object.id)
  end

  def is_member
    scope.is_admin? || GroupUser.where(group_id: object.id, user_id: scope.user.id).present?
  end

  def include_is_member?
    scope.authenticated?
  end

end
