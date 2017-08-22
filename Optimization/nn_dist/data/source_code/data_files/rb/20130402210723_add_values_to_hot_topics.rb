class AddValuesToHotTopics < ActiveRecord::Migration
  def change
    add_column :hot_topics, :random_bias, :float
    add_column :hot_topics, :random_multiplier, :float
    add_column :hot_topics, :days_ago_bias, :float
    add_column :hot_topics, :days_ago_multiplier, :float
    add_column :hot_topics, :hot_topic_type, :integer
  end
end
