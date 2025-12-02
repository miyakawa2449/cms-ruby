class CreateDatabaseFunctions < ActiveRecord::Migration[8.0]
  def up
    # 全文検索トリガー（PostgreSQL Alpine = 英語辞書）
    execute <<-SQL
      CREATE TRIGGER update_articles_search_vector 
      BEFORE INSERT OR UPDATE ON articles 
      FOR EACH ROW EXECUTE FUNCTION 
      tsvector_update_trigger(search_vector, 'pg_catalog.english', title, content, excerpt);
    SQL
    
    # カテゴリ記事数更新関数
    execute <<-SQL
      CREATE OR REPLACE FUNCTION update_category_article_count() 
      RETURNS TRIGGER AS $$
      BEGIN
        IF TG_OP = 'INSERT' THEN
          UPDATE categories 
          SET article_count = article_count + 1 
          WHERE id = NEW.category_id;
        ELSIF TG_OP = 'DELETE' THEN
          UPDATE categories 
          SET article_count = article_count - 1 
          WHERE id = OLD.category_id;
        END IF;
        RETURN NULL;
      END;
      $$ LANGUAGE plpgsql;
    SQL
    
    execute <<-SQL
      CREATE TRIGGER trigger_update_category_count
      AFTER INSERT OR DELETE ON article_categories
      FOR EACH ROW EXECUTE FUNCTION update_category_article_count();
    SQL
    
    # メディア使用状況更新関数
    execute <<-SQL
      CREATE OR REPLACE FUNCTION update_media_usage() 
      RETURNS TRIGGER AS $$
      BEGIN
        UPDATE media_files 
        SET usage_count = (
          SELECT COUNT(*) FROM article_media 
          WHERE media_file_id = NEW.media_file_id
        ),
        last_used_at = NOW()
        WHERE id = NEW.media_file_id;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    SQL
    
    execute <<-SQL
      CREATE TRIGGER trigger_update_media_usage
      AFTER INSERT ON article_media
      FOR EACH ROW EXECUTE FUNCTION update_media_usage();
    SQL
    
    # 月次パーティション自動作成関数
    execute <<-SQL
      CREATE OR REPLACE FUNCTION create_monthly_partition() 
      RETURNS void AS $$
      DECLARE
        start_date date;
        end_date date;
        partition_name text;
      BEGIN
        start_date := date_trunc('month', CURRENT_DATE + interval '1 month');
        end_date := start_date + interval '1 month';
        partition_name := 'access_logs_' || to_char(start_date, 'YYYY_MM');
        
        EXECUTE format('
          CREATE TABLE IF NOT EXISTS %I PARTITION OF access_logs
          FOR VALUES FROM (%L) TO (%L)',
          partition_name, start_date, end_date
        );
        
        EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON %I (created_at)', 
                      'idx_' || partition_name || '_created_at', partition_name);
        EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON %I (path)', 
                      'idx_' || partition_name || '_path', partition_name);
        EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON %I (admin_user_id)', 
                      'idx_' || partition_name || '_admin_user_id', partition_name);
      END;
      $$ LANGUAGE plpgsql;
    SQL
    
    # タグ記事数更新関数
    execute <<-SQL
      CREATE OR REPLACE FUNCTION update_tag_article_count() 
      RETURNS TRIGGER AS $$
      BEGIN
        IF TG_OP = 'INSERT' THEN
          UPDATE tags 
          SET article_count = article_count + 1 
          WHERE id = NEW.tag_id;
        ELSIF TG_OP = 'DELETE' THEN
          UPDATE tags 
          SET article_count = article_count - 1 
          WHERE id = OLD.tag_id;
        END IF;
        RETURN NULL;
      END;
      $$ LANGUAGE plpgsql;
    SQL
    
    execute <<-SQL
      CREATE TRIGGER trigger_update_tag_count
      AFTER INSERT OR DELETE ON article_tags
      FOR EACH ROW EXECUTE FUNCTION update_tag_article_count();
    SQL
    
    # コメント数更新関数
    execute <<-SQL
      CREATE OR REPLACE FUNCTION update_article_comment_count() 
      RETURNS TRIGGER AS $$
      BEGIN
        IF TG_OP = 'INSERT' THEN
          UPDATE articles 
          SET comment_count = comment_count + 1 
          WHERE id = NEW.article_id;
        ELSIF TG_OP = 'DELETE' THEN
          UPDATE articles 
          SET comment_count = comment_count - 1 
          WHERE id = OLD.article_id;
        END IF;
        RETURN NULL;
      END;
      $$ LANGUAGE plpgsql;
    SQL
    
    execute <<-SQL
      CREATE TRIGGER trigger_update_article_comment_count
      AFTER INSERT OR DELETE ON comments
      FOR EACH ROW EXECUTE FUNCTION update_article_comment_count();
    SQL
  end
  
  def down
    execute "DROP TRIGGER IF EXISTS update_articles_search_vector ON articles;"
    execute "DROP TRIGGER IF EXISTS trigger_update_category_count ON article_categories;"
    execute "DROP TRIGGER IF EXISTS trigger_update_media_usage ON article_media;"
    execute "DROP TRIGGER IF EXISTS trigger_update_tag_count ON article_tags;"
    execute "DROP TRIGGER IF EXISTS trigger_update_article_comment_count ON comments;"
    
    execute "DROP FUNCTION IF EXISTS update_category_article_count();"
    execute "DROP FUNCTION IF EXISTS update_media_usage();"
    execute "DROP FUNCTION IF EXISTS create_monthly_partition();"
    execute "DROP FUNCTION IF EXISTS update_tag_article_count();"
    execute "DROP FUNCTION IF EXISTS update_article_comment_count();"
  end
end