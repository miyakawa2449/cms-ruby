class CreateDatabaseFunctions < ActiveRecord::Migration[8.0]
  def up
    # ========================================
    # COUNTER CACHE UPDATE FUNCTIONS
    # ========================================
    
    # Function to update articles count for categories
    execute <<-SQL
      CREATE OR REPLACE FUNCTION update_category_articles_count()
      RETURNS TRIGGER AS $$
      BEGIN
        IF TG_OP = 'INSERT' THEN
          UPDATE categories 
          SET articles_count = (
            SELECT COUNT(*) 
            FROM article_categories ac
            JOIN articles a ON ac.article_id = a.id
            WHERE ac.category_id = NEW.category_id 
            AND a.status = 'published'
          )
          WHERE id = NEW.category_id;
          RETURN NEW;
        ELSIF TG_OP = 'DELETE' THEN
          UPDATE categories 
          SET articles_count = (
            SELECT COUNT(*) 
            FROM article_categories ac
            JOIN articles a ON ac.article_id = a.id
            WHERE ac.category_id = OLD.category_id 
            AND a.status = 'published'
          )
          WHERE id = OLD.category_id;
          RETURN OLD;
        END IF;
        RETURN NULL;
      END;
      $$ LANGUAGE plpgsql;
    SQL
    
    # Function to update articles count for tags
    execute <<-SQL
      CREATE OR REPLACE FUNCTION update_tag_articles_count()
      RETURNS TRIGGER AS $$
      BEGIN
        IF TG_OP = 'INSERT' THEN
          UPDATE tags 
          SET articles_count = (
            SELECT COUNT(*) 
            FROM article_tags at
            JOIN articles a ON at.article_id = a.id
            WHERE at.tag_id = NEW.tag_id 
            AND a.status = 'published'
          ),
          usage_count = usage_count + 1
          WHERE id = NEW.tag_id;
          RETURN NEW;
        ELSIF TG_OP = 'DELETE' THEN
          UPDATE tags 
          SET articles_count = (
            SELECT COUNT(*) 
            FROM article_tags at
            JOIN articles a ON at.article_id = a.id
            WHERE at.tag_id = OLD.tag_id 
            AND a.status = 'published'
          ),
          usage_count = GREATEST(usage_count - 1, 0)
          WHERE id = OLD.tag_id;
          RETURN OLD;
        END IF;
        RETURN NULL;
      END;
      $$ LANGUAGE plpgsql;
    SQL
    
    # Function to update comments count for articles
    execute <<-SQL
      CREATE OR REPLACE FUNCTION update_article_comments_count()
      RETURNS TRIGGER AS $$
      BEGIN
        IF TG_OP = 'INSERT' THEN
          UPDATE articles 
          SET comments_count = (
            SELECT COUNT(*) 
            FROM comments 
            WHERE article_id = NEW.article_id 
            AND status = 'approved'
          )
          WHERE id = NEW.article_id;
          RETURN NEW;
        ELSIF TG_OP = 'UPDATE' THEN
          -- Handle status changes
          IF OLD.status != NEW.status THEN
            UPDATE articles 
            SET comments_count = (
              SELECT COUNT(*) 
              FROM comments 
              WHERE article_id = NEW.article_id 
              AND status = 'approved'
            )
            WHERE id = NEW.article_id;
          END IF;
          RETURN NEW;
        ELSIF TG_OP = 'DELETE' THEN
          UPDATE articles 
          SET comments_count = (
            SELECT COUNT(*) 
            FROM comments 
            WHERE article_id = OLD.article_id 
            AND status = 'approved'
          )
          WHERE id = OLD.article_id;
          RETURN OLD;
        END IF;
        RETURN NULL;
      END;
      $$ LANGUAGE plpgsql;
    SQL
    
    # Function to update replies count for comments
    execute <<-SQL
      CREATE OR REPLACE FUNCTION update_comment_replies_count()
      RETURNS TRIGGER AS $$
      BEGIN
        IF TG_OP = 'INSERT' AND NEW.parent_id IS NOT NULL THEN
          UPDATE comments 
          SET replies_count = (
            SELECT COUNT(*) 
            FROM comments 
            WHERE parent_id = NEW.parent_id 
            AND status = 'approved'
          )
          WHERE id = NEW.parent_id;
          RETURN NEW;
        ELSIF TG_OP = 'UPDATE' AND NEW.parent_id IS NOT NULL THEN
          -- Handle status changes
          IF OLD.status != NEW.status THEN
            UPDATE comments 
            SET replies_count = (
              SELECT COUNT(*) 
              FROM comments 
              WHERE parent_id = NEW.parent_id 
              AND status = 'approved'
            )
            WHERE id = NEW.parent_id;
          END IF;
          RETURN NEW;
        ELSIF TG_OP = 'DELETE' AND OLD.parent_id IS NOT NULL THEN
          UPDATE comments 
          SET replies_count = (
            SELECT COUNT(*) 
            FROM comments 
            WHERE parent_id = OLD.parent_id 
            AND status = 'approved'
          )
          WHERE id = OLD.parent_id;
          RETURN OLD;
        END IF;
        RETURN NULL;
      END;
      $$ LANGUAGE plpgsql;
    SQL
    
    # Function to update media usage count
    execute <<-SQL
      CREATE OR REPLACE FUNCTION update_media_usage_count()
      RETURNS TRIGGER AS $$
      BEGIN
        IF TG_OP = 'INSERT' THEN
          UPDATE media_files 
          SET usage_count = usage_count + 1,
              last_used_at = CURRENT_TIMESTAMP
          WHERE id = NEW.media_file_id;
          RETURN NEW;
        ELSIF TG_OP = 'DELETE' THEN
          UPDATE media_files 
          SET usage_count = GREATEST(usage_count - 1, 0)
          WHERE id = OLD.media_file_id;
          RETURN OLD;
        END IF;
        RETURN NULL;
      END;
      $$ LANGUAGE plpgsql;
    SQL
    
    # ========================================
    # HIERARCHY MANAGEMENT FUNCTIONS
    # ========================================
    
    # Function to update category path and children count
    execute <<-SQL
      CREATE OR REPLACE FUNCTION update_category_hierarchy()
      RETURNS TRIGGER AS $$
      BEGIN
        IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
          -- Update path
          IF NEW.parent_id IS NULL THEN
            NEW.path = NEW.slug;
            NEW.depth = 0;
          ELSE
            SELECT path || '/' || NEW.slug, depth + 1
            INTO NEW.path, NEW.depth
            FROM categories 
            WHERE id = NEW.parent_id;
          END IF;
          
          -- Update parent's children count
          IF NEW.parent_id IS NOT NULL THEN
            UPDATE categories 
            SET children_count = (
              SELECT COUNT(*) 
              FROM categories 
              WHERE parent_id = NEW.parent_id
            )
            WHERE id = NEW.parent_id;
          END IF;
          
          RETURN NEW;
        ELSIF TG_OP = 'DELETE' THEN
          -- Update parent's children count
          IF OLD.parent_id IS NOT NULL THEN
            UPDATE categories 
            SET children_count = (
              SELECT COUNT(*) 
              FROM categories 
              WHERE parent_id = OLD.parent_id
            )
            WHERE id = OLD.parent_id;
          END IF;
          
          RETURN OLD;
        END IF;
        RETURN NULL;
      END;
      $$ LANGUAGE plpgsql;
    SQL
    
    # ========================================
    # CONTENT PROCESSING FUNCTIONS
    # ========================================
    
    # Function to calculate reading time
    execute <<-SQL
      CREATE OR REPLACE FUNCTION calculate_reading_time(content_text TEXT)
      RETURNS INTEGER AS $$
      BEGIN
        -- Average reading speed: 200 words per minute
        -- Calculate word count and convert to minutes
        RETURN GREATEST(
          CEIL(
            array_length(string_to_array(content_text, ' '), 1) / 200.0
          )::INTEGER,
          1
        );
      END;
      $$ LANGUAGE plpgsql IMMUTABLE;
    SQL
    
    # Function to update article word count and reading time
    execute <<-SQL
      CREATE OR REPLACE FUNCTION update_article_stats()
      RETURNS TRIGGER AS $$
      BEGIN
        -- Calculate word count
        NEW.word_count = array_length(
          string_to_array(NEW.content, ' '), 1
        );
        
        -- Calculate reading time
        NEW.reading_time = calculate_reading_time(NEW.content);
        
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    SQL
    
    # ========================================
    # SEARCH VECTOR UPDATE FUNCTIONS
    # ========================================
    
    # Function to update article search vector
    execute <<-SQL
      CREATE OR REPLACE FUNCTION update_article_search_vector()
      RETURNS TRIGGER AS $$
      BEGIN
        NEW.search_vector = to_tsvector('japanese', 
          coalesce(NEW.title, '') || ' ' || 
          coalesce(NEW.excerpt, '') || ' ' || 
          coalesce(NEW.content, '')
        );
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    SQL
    
    # ========================================
    # PARTITIONING FUNCTIONS
    # ========================================
    
    # Function to create access_logs partitions
    execute <<-SQL
      CREATE OR REPLACE FUNCTION create_access_logs_partition(partition_date DATE)
      RETURNS BOOLEAN AS $$
      DECLARE
        partition_name TEXT;
        start_date DATE;
        end_date DATE;
      BEGIN
        partition_name = 'access_logs_' || to_char(partition_date, 'YYYY_MM_DD');
        start_date = partition_date;
        end_date = partition_date + INTERVAL '1 day';
        
        -- Check if partition already exists
        IF EXISTS (
          SELECT 1 FROM pg_tables 
          WHERE tablename = partition_name
        ) THEN
          RETURN FALSE;
        END IF;
        
        -- Create partition
        EXECUTE format('
          CREATE TABLE %I PARTITION OF access_logs
          FOR VALUES FROM (%L) TO (%L)',
          partition_name, start_date, end_date
        );
        
        -- Create indexes on partition
        EXECUTE format('
          CREATE INDEX %I ON %I (timestamp, ip_address)',
          partition_name || '_timestamp_ip_idx', partition_name
        );
        
        RETURN TRUE;
      END;
      $$ LANGUAGE plpgsql;
    SQL
    
    # Function to auto-create access_logs partitions
    execute <<-SQL
      CREATE OR REPLACE FUNCTION auto_create_access_logs_partition()
      RETURNS TRIGGER AS $$
      BEGIN
        PERFORM create_access_logs_partition(NEW.log_date);
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    SQL
    
    # ========================================
    # CLEANUP FUNCTIONS
    # ========================================
    
    # Function to clean up old access logs
    execute <<-SQL
      CREATE OR REPLACE FUNCTION cleanup_old_access_logs(retention_days INTEGER DEFAULT 90)
      RETURNS INTEGER AS $$
      DECLARE
        cleanup_date DATE;
        deleted_count INTEGER;
      BEGIN
        cleanup_date = CURRENT_DATE - retention_days;
        
        DELETE FROM access_logs 
        WHERE log_date < cleanup_date;
        
        GET DIAGNOSTICS deleted_count = ROW_COUNT;
        RETURN deleted_count;
      END;
      $$ LANGUAGE plpgsql;
    SQL
    
    # Function to clean up expired backups
    execute <<-SQL
      CREATE OR REPLACE FUNCTION cleanup_expired_backups()
      RETURNS INTEGER AS $$
      DECLARE
        deleted_count INTEGER;
      BEGIN
        DELETE FROM backups 
        WHERE auto_delete = true 
        AND expires_at < CURRENT_TIMESTAMP;
        
        GET DIAGNOSTICS deleted_count = ROW_COUNT;
        RETURN deleted_count;
      END;
      $$ LANGUAGE plpgsql;
    SQL
    
    # ========================================
    # CREATE TRIGGERS
    # ========================================
    
    # Triggers for counter cache updates
    execute <<-SQL
      CREATE TRIGGER trigger_update_category_articles_count
        AFTER INSERT OR DELETE ON article_categories
        FOR EACH ROW EXECUTE FUNCTION update_category_articles_count();
    SQL
    
    execute <<-SQL
      CREATE TRIGGER trigger_update_tag_articles_count
        AFTER INSERT OR DELETE ON article_tags
        FOR EACH ROW EXECUTE FUNCTION update_tag_articles_count();
    SQL
    
    execute <<-SQL
      CREATE TRIGGER trigger_update_article_comments_count
        AFTER INSERT OR UPDATE OR DELETE ON comments
        FOR EACH ROW EXECUTE FUNCTION update_article_comments_count();
    SQL
    
    execute <<-SQL
      CREATE TRIGGER trigger_update_comment_replies_count
        AFTER INSERT OR UPDATE OR DELETE ON comments
        FOR EACH ROW EXECUTE FUNCTION update_comment_replies_count();
    SQL
    
    execute <<-SQL
      CREATE TRIGGER trigger_update_media_usage_count
        AFTER INSERT OR DELETE ON article_media
        FOR EACH ROW EXECUTE FUNCTION update_media_usage_count();
    SQL
    
    # Triggers for hierarchy management
    execute <<-SQL
      CREATE TRIGGER trigger_update_category_hierarchy
        BEFORE INSERT OR UPDATE ON categories
        FOR EACH ROW EXECUTE FUNCTION update_category_hierarchy();
    SQL
    
    # Triggers for content processing
    execute <<-SQL
      CREATE TRIGGER trigger_update_article_stats
        BEFORE INSERT OR UPDATE ON articles
        FOR EACH ROW EXECUTE FUNCTION update_article_stats();
    SQL
    
    execute <<-SQL
      CREATE TRIGGER trigger_update_article_search_vector
        BEFORE INSERT OR UPDATE ON articles
        FOR EACH ROW EXECUTE FUNCTION update_article_search_vector();
    SQL
    
    # Triggers for partitioning (commented out - requires manual partition creation)
    # execute <<-SQL
    #   CREATE TRIGGER trigger_auto_create_access_logs_partition
    #     BEFORE INSERT ON access_logs
    #     FOR EACH ROW EXECUTE FUNCTION auto_create_access_logs_partition();
    # SQL
    
    # Add comments about functions
    execute <<-SQL
      COMMENT ON FUNCTION update_category_articles_count() IS 'Maintains articles_count in categories table';
      COMMENT ON FUNCTION update_tag_articles_count() IS 'Maintains articles_count and usage_count in tags table';
      COMMENT ON FUNCTION calculate_reading_time(TEXT) IS 'Calculates estimated reading time in minutes';
      COMMENT ON FUNCTION cleanup_old_access_logs(INTEGER) IS 'Removes access logs older than specified days';
    SQL
  end

  def down
    # Drop triggers first
    execute "DROP TRIGGER IF EXISTS trigger_update_category_articles_count ON article_categories;"
    execute "DROP TRIGGER IF EXISTS trigger_update_tag_articles_count ON article_tags;"
    execute "DROP TRIGGER IF EXISTS trigger_update_article_comments_count ON comments;"
    execute "DROP TRIGGER IF EXISTS trigger_update_comment_replies_count ON comments;"
    execute "DROP TRIGGER IF EXISTS trigger_update_media_usage_count ON article_media;"
    execute "DROP TRIGGER IF EXISTS trigger_update_category_hierarchy ON categories;"
    execute "DROP TRIGGER IF EXISTS trigger_update_article_stats ON articles;"
    execute "DROP TRIGGER IF EXISTS trigger_update_article_search_vector ON articles;"
    execute "DROP TRIGGER IF EXISTS trigger_auto_create_access_logs_partition ON access_logs;"
    
    # Drop functions
    execute "DROP FUNCTION IF EXISTS update_category_articles_count();"
    execute "DROP FUNCTION IF EXISTS update_tag_articles_count();"
    execute "DROP FUNCTION IF EXISTS update_article_comments_count();"
    execute "DROP FUNCTION IF EXISTS update_comment_replies_count();"
    execute "DROP FUNCTION IF EXISTS update_media_usage_count();"
    execute "DROP FUNCTION IF EXISTS update_category_hierarchy();"
    execute "DROP FUNCTION IF EXISTS calculate_reading_time(TEXT);"
    execute "DROP FUNCTION IF EXISTS update_article_stats();"
    execute "DROP FUNCTION IF EXISTS update_article_search_vector();"
    execute "DROP FUNCTION IF EXISTS create_access_logs_partition(DATE);"
    execute "DROP FUNCTION IF EXISTS auto_create_access_logs_partition();"
    execute "DROP FUNCTION IF EXISTS cleanup_old_access_logs(INTEGER);"
    execute "DROP FUNCTION IF EXISTS cleanup_expired_backups();"
  end
end