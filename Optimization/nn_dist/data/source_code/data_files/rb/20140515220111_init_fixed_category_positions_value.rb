class InitFixedCategoryPositionsValue < ActiveRecord::Migration
  def up
    # Look at existing categories to determine if positions have been specified
    result = Category.exec_sql("SELECT count(*) FROM categories WHERE position IS NOT NULL")

    # Greater than 4 because uncategorized, meta, staff, lounge all have positions by default
    if result[0]['count'].to_i > 4
      execute "INSERT INTO site_settings (name, data_type, value, created_at, updated_at) VALUES ('fixed_category_positions', 5, 't', now(), now())"
    end
  end

  def down
    execute "DELETE FROM site_settings WHERE name = 'fixed_category_positions'"
  end
end
