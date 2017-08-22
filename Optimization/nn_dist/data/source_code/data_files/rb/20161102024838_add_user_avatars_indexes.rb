class AddUserAvatarsIndexes < ActiveRecord::Migration
  def change
    add_index :user_avatars, :custom_upload_id
    add_index :user_avatars, :gravatar_upload_id
  end
end
