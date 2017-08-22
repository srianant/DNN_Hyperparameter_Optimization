class RemoveIndexFromViews < ActiveRecord::Migration
  def up
    remove_index "views", name: "unique_views"
    change_column :views, :viewed_at, :date
  end

  def down
    add_index "views", ["parent_id", "parent_type", "ip", "viewed_at"], name: "unique_views", unique: true
    change_column :views, :viewed_at, :timestamp
  end
end
