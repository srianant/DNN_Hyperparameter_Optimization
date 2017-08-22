class CreateColorSchemeColors < ActiveRecord::Migration
  def change
    create_table :color_scheme_colors do |t|
      t.string  :name,            null: false
      t.string  :hex,             null: false
      t.integer :opacity,         null: false, default: 100
      t.integer :color_scheme_id, null: false

      t.timestamps
    end

    add_index :color_scheme_colors, [:color_scheme_id]
  end
end
