class AddEmailDirectToUsers < ActiveRecord::Migration
  def change
    add_column :users, :email_direct, :boolean, default: true, null: false
    remove_column :users, :email_mentions
    remove_column :users, :email_replied
    remove_column :users, :email_quoted
  end
end
