class SetDefaultS3Region < ActiveRecord::Migration
  def up
    execute <<-SQL
      UPDATE site_settings
         SET value = 'us-east-1'
       WHERE name = 's3_region'
         AND LENGTH(COALESCE(value, '')) = 0
    SQL
  end

  def down
  end
end
