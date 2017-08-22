class CreateJoinTableWebHooksCategories < ActiveRecord::Migration
  def change
    create_join_table :web_hooks, :categories
    add_index :categories_web_hooks, [:web_hook_id, :category_id], unique: true
  end
end
