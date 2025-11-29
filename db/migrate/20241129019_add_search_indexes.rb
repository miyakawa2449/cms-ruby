class AddSearchIndexes < ActiveRecord::Migration[8.0]
  def up
    # Enable PostgreSQL extensions for full-text search and trigram similarity
    enable_extension 'pg_trgm' unless extension_enabled?('pg_trgm')
    enable_extension 'btree_gin' unless extension_enabled?('btree_gin')
    enable_extension 'btree_gist' unless extension_enabled?('btree_gist')
    
    # Create text search configuration for Japanese
    execute <<-SQL
      CREATE TEXT SEARCH CONFIGURATION IF NOT EXISTS japanese (COPY = pg_catalog.simple);
    SQL
    
    # ========================================
    # GLOBAL FULL-TEXT SEARCH
    # ========================================
    
    # Global search across multiple content types
    execute <<-SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS index_global_content_search 
      ON articles USING gin(
        to_tsvector('japanese', 
          coalesce(title, '') || ' ' || 
          coalesce(excerpt, '') || ' ' || 
          coalesce(content, '')
        )
      );
    SQL
    
    execute <<-SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS index_global_portfolio_search 
      ON section_contents USING gin(
        to_tsvector('japanese', 
          coalesce(title, '') || ' ' || 
          coalesce(subtitle, '') || ' ' ||
          coalesce(content_data::text, '')
        )
      );
    SQL
    
    # ========================================
    # TRIGRAM INDEXES FOR FUZZY SEARCH
    # ========================================
    
    # Articles trigram indexes (already created in articles migration, but ensuring they exist)
    execute <<-SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS index_articles_title_excerpt_trgm 
      ON articles USING gin(
        (title || ' ' || coalesce(excerpt, '')) gin_trgm_ops
      );
    SQL
    
    # Categories and tags combined search
    execute <<-SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS index_categories_tags_combined_trgm 
      ON categories USING gin(
        (name || ' ' || coalesce(description, '')) gin_trgm_ops
      );
    SQL
    
    # ========================================
    # PERFORMANCE COMPOSITE INDEXES
    # ========================================
    
    # Article listing performance
    execute <<-SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS index_articles_listing_performance
      ON articles (published_at DESC, id DESC)
      WHERE status = 'published' AND published_at IS NOT NULL;
    SQL
    
    # Category hierarchy performance
    execute <<-SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS index_categories_hierarchy_performance
      ON categories (path, depth, sort_order)
      WHERE visible = true;
    SQL
    
    # Article-category performance for category pages
    execute <<-SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS index_article_categories_performance
      ON article_categories (category_id, article_id)
      INCLUDE (primary, sort_order);
    SQL
    
    # Media usage tracking performance
    execute <<-SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS index_media_files_usage_performance
      ON media_files (usage_count DESC, last_used_at DESC)
      WHERE public = true;
    SQL
    
    # ========================================
    # ANALYTICS AND REPORTING INDEXES
    # ========================================
    
    # Access logs analytics (time-series queries)
    execute <<-SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS index_access_logs_analytics_hourly
      ON access_logs (date_trunc('hour', timestamp), status_code)
      WHERE is_bot = false;
    SQL
    
    execute <<-SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS index_access_logs_analytics_daily
      ON access_logs (log_date, path, status_code)
      WHERE is_bot = false;
    SQL
    
    # Popular content tracking
    execute <<-SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS index_articles_popularity
      ON articles (views_count DESC, published_at DESC)
      WHERE status = 'published' AND views_count > 0;
    SQL
    
    # ========================================
    # ADMIN INTERFACE PERFORMANCE
    # ========================================
    
    # Article management dashboard
    execute <<-SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS index_articles_admin_dashboard
      ON articles (admin_user_id, status, updated_at DESC)
      INCLUDE (title, published_at);
    SQL
    
    # Comment moderation queue
    execute <<-SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS index_comments_moderation_queue
      ON comments (status, spam_score DESC, created_at DESC)
      WHERE status IN ('pending', 'spam');
    SQL
    
    # Media library organization
    execute <<-SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS index_media_files_library
      ON media_files (folder, content_type, created_at DESC)
      WHERE public = true;
    SQL
    
    # ========================================
    # SPATIAL/GEOGRAPHIC INDEXES
    # ========================================
    
    # Geographic distribution of visitors
    execute <<-SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS index_access_logs_geographic
      ON access_logs (country_code, region, city)
      WHERE country_code IS NOT NULL AND is_bot = false;
    SQL
    
    # ========================================
    # PARTITIONING SUPPORT INDEXES
    # ========================================
    
    # Support for access_logs partitioning
    execute <<-SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS index_access_logs_partition_support
      ON access_logs (log_date, timestamp, path)
      WHERE status_code < 400;
    SQL
    
    # ========================================
    # JSON/JSONB SPECIALIZED INDEXES
    # ========================================
    
    # Settings search by category and key
    execute <<-SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS index_settings_category_search
      ON settings (category, key)
      INCLUDE (value, value_type);
    SQL
    
    # Article custom fields search
    execute <<-SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS index_articles_custom_fields_search
      ON articles USING gin(custom_fields)
      WHERE custom_fields != '{}';
    SQL
    
    # Portfolio sections settings search
    execute <<-SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS index_portfolio_sections_settings_search
      ON portfolio_sections USING gin(settings)
      WHERE settings != '{}';
    SQL
    
    # ========================================
    # API PERFORMANCE INDEXES
    # ========================================
    
    # API response optimization for articles
    execute <<-SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS index_articles_api_response
      ON articles (slug, status, published_at)
      INCLUDE (title, excerpt, updated_at)
      WHERE status = 'published';
    SQL
    
    # API pagination support
    execute <<-SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS index_articles_api_pagination
      ON articles (published_at DESC, id DESC)
      WHERE status = 'published';
    SQL
    
    # Category API with article counts
    execute <<-SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS index_categories_api_with_counts
      ON categories (visible, sort_order)
      INCLUDE (name, slug, articles_count)
      WHERE visible = true;
    SQL
    
    # ========================================
    # CACHE WARMING INDEXES
    # ========================================
    
    # Featured content cache warming
    execute <<-SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS index_featured_content_cache
      ON articles (featured, published_at DESC)
      WHERE status = 'published' AND featured = true;
    SQL
    
    # Recent content cache warming
    execute <<-SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS index_recent_content_cache
      ON articles (published_at DESC)
      WHERE status = 'published' AND published_at >= (CURRENT_DATE - INTERVAL '30 days');
    SQL
    
    # Add comments about index purposes
    execute <<-SQL
      COMMENT ON INDEX index_global_content_search IS 'Full-text search across all article content in Japanese';
      COMMENT ON INDEX index_articles_listing_performance IS 'Optimizes article listing queries for public pages';
      COMMENT ON INDEX index_access_logs_analytics_hourly IS 'Supports real-time analytics dashboard queries';
      COMMENT ON INDEX index_articles_api_response IS 'Optimizes API responses for article endpoints';
    SQL
  end

  def down
    # Remove custom indexes (PostgreSQL extensions will remain for other potential usage)
    
    custom_indexes = %w[
      index_global_content_search
      index_global_portfolio_search
      index_articles_title_excerpt_trgm
      index_categories_tags_combined_trgm
      index_articles_listing_performance
      index_categories_hierarchy_performance
      index_article_categories_performance
      index_media_files_usage_performance
      index_access_logs_analytics_hourly
      index_access_logs_analytics_daily
      index_articles_popularity
      index_articles_admin_dashboard
      index_comments_moderation_queue
      index_media_files_library
      index_access_logs_geographic
      index_access_logs_partition_support
      index_settings_category_search
      index_articles_custom_fields_search
      index_portfolio_sections_settings_search
      index_articles_api_response
      index_articles_api_pagination
      index_categories_api_with_counts
      index_featured_content_cache
      index_recent_content_cache
    ]
    
    custom_indexes.each do |index_name|
      execute "DROP INDEX CONCURRENTLY IF EXISTS #{index_name};"
    end
    
    # Remove custom text search configuration
    execute "DROP TEXT SEARCH CONFIGURATION IF EXISTS japanese;"
  end
end