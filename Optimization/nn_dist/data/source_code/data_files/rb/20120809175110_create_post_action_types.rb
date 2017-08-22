class CreatePostActionTypes < ActiveRecord::Migration
  def change
    create_table(:post_action_types, id: false) do |t|
      t.integer :id, options: "PRIMARY KEY", null: false
      t.string :name, null: false, limit: 50
      t.string :long_form, null: false, limit: 100
      t.boolean :is_flag, null: false, default: false
      t.text :description
      t.string :icon, limit: 20

      t.timestamps
    end
  end
end
