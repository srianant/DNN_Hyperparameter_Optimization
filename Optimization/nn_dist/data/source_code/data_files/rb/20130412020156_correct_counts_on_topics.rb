class CorrectCountsOnTopics < ActiveRecord::Migration
  def change
    rename_column :topics, :custom_flag_count, :notify_moderators_count
    add_column :topics, :notify_user_count, :integer, default: 0, null: false
  end
end
