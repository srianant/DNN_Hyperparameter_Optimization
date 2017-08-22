class CreatePosts < ActiveRecord::Migration
  def change
    create_table :posts do |t|
      t.integer :user_id, null: false
      t.integer :forum_thread_id, null: false
      t.integer :post_number, null: false
      t.text :content, null: false
      t.text :formatted_content, null: false
      t.timestamps
    end

    add_index :posts, [:forum_thread_id, :created_at]
  end
end
