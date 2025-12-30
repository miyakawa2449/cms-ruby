class EnablePgTrgmExtension < ActiveRecord::Migration[8.1]
  def up
    # Enable pg_trgm extension for trigram-based full-text search
    enable_extension 'pg_trgm'

    # Add GIN indexes for fast trigram search on articles
    execute <<-SQL
      CREATE INDEX IF NOT EXISTS index_articles_on_title_gin_trgm
      ON articles USING gin (title gin_trgm_ops);
    SQL

    execute <<-SQL
      CREATE INDEX IF NOT EXISTS index_articles_on_content_gin_trgm
      ON articles USING gin (content gin_trgm_ops);
    SQL

    execute <<-SQL
      CREATE INDEX IF NOT EXISTS index_articles_on_excerpt_gin_trgm
      ON articles USING gin (excerpt gin_trgm_ops);
    SQL
  end

  def down
    execute "DROP INDEX IF EXISTS index_articles_on_title_gin_trgm;"
    execute "DROP INDEX IF EXISTS index_articles_on_content_gin_trgm;"
    execute "DROP INDEX IF EXISTS index_articles_on_excerpt_gin_trgm;"

    disable_extension 'pg_trgm'
  end
end
