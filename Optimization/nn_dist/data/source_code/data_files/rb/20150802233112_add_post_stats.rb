class AddPostStats < ActiveRecord::Migration
  def change

    add_column :drafts, :revisions, :int, null: false, default: 1

    create_table :post_stats do |t|
      t.integer :post_id
      t.integer :drafts_saved
      t.integer :typing_duration_msecs
      t.integer :composer_open_duration_msecs
      t.timestamps
    end

    add_index :post_stats, [:post_id]
  end
end
