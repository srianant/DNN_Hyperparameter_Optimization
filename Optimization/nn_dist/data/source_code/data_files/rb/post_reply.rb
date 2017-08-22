class PostReply < ActiveRecord::Base
  belongs_to :post
  belongs_to :reply, class_name: 'Post'

  validates_uniqueness_of :reply_id, scope: :post_id
  validate :ensure_same_topic

  private

  def ensure_same_topic
    if post.topic_id != reply.topic_id
      self.errors.add(
        :base,
        I18n.t("activerecord.errors.models.post_reply.base.different_topic")
      )
    end
  end
end

# == Schema Information
#
# Table name: post_replies
#
#  post_id    :integer
#  reply_id   :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_post_replies_on_post_id_and_reply_id  (post_id,reply_id) UNIQUE
#
