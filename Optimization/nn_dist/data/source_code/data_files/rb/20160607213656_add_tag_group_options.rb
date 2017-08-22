class AddTagGroupOptions < ActiveRecord::Migration
  def change
    add_column :tag_groups, :parent_tag_id, :integer
    add_column :tag_groups, :one_per_topic, :boolean, default: false
  end
end
