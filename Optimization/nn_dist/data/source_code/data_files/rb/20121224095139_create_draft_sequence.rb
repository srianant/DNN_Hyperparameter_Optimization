class CreateDraftSequence < ActiveRecord::Migration
  def change
    create_table :draft_sequences do |t|
      t.integer :user_id, null: false
      t.string :draft_key, null: false
      t.integer :sequence, null: false
    end
    add_index :draft_sequences, [:user_id, :draft_key], unique: true
  end
end
