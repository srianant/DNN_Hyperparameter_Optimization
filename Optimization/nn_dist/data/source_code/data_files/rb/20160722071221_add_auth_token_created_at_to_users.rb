class AddAuthTokenCreatedAtToUsers < ActiveRecord::Migration
  def change
    add_column :users, :auth_token_created_at, :datetime, null: true
  end
end
