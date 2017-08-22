class IndexTopicsForFrontPage < ActiveRecord::Migration
  def change
    add_index :topics, [:deleted_at, :visible, :archetype, :id]
    # covering index for join
    add_index :topics, [:id, :deleted_at]
  end

end
