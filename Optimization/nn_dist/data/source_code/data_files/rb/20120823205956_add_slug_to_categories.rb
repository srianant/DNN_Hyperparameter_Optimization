class AddSlugToCategories < ActiveRecord::Migration
  def change
    add_column :categories, :slug, :string
    execute "UPDATE categories SET slug = REPLACE(LOWER(name), ' ', '-')"
    change_column :categories, :slug, :string, null: false
  end
end
