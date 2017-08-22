class BadgesOnlyOnPublicCategories < ActiveRecord::Migration
  def up
    execute "DROP VIEW badge_posts"

    execute "CREATE VIEW badge_posts AS
    SELECT p.*
    FROM posts p
    JOIN topics t ON t.id = p.topic_id
    JOIN categories c ON c.id = t.category_id
    WHERE c.allow_badges AND
          p.deleted_at IS NULL AND
          t.deleted_at IS NULL AND
          NOT c.read_restricted AND
          t.visible"
  end

  def down
    execute "DROP VIEW badge_posts"

    execute "CREATE VIEW badge_posts AS
    SELECT p.*
    FROM posts p
    JOIN topics t ON t.id = p.topic_id
    JOIN categories c ON c.id = t.category_id
    WHERE c.allow_badges AND
          p.deleted_at IS NULL AND
          t.deleted_at IS NULL AND
          t.visible"
  end
end
