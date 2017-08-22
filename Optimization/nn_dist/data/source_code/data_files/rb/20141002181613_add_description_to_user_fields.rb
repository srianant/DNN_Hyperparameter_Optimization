class AddDescriptionToUserFields < ActiveRecord::Migration
  def change
    add_column :user_fields, :description, :string, null: true
    execute "UPDATE user_fields SET description=name"
    change_column :user_fields, :description, :string, null: false
  end
end
