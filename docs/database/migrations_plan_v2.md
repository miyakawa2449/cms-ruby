# Railsマイグレーション実装計画 v2.0 (Rails 8.0対応版)

## 🎯 改訂方針
**Rails 8.0外部キー自動インデックス活用・PostgreSQL Alpine制約対応・Devise統合明確化**

## 📋 改訂履歴
- **v2.0** (2025-12-02): Rails 8.0対応・重複インデックス排除・Devise統合明確化
- **v1.0**: 初版（マイグレーション複雑化により改訂）

## 概要
スキーマ設計v2.0に基づいたRails 8.0対応マイグレーション実装計画。外部キー自動インデックス機能を活用し、PostgreSQL Alpine版制約に対応。

**重要な改良点**:
- **Rails 8.0活用**: 外部キー自動インデックス機能で重複排除
- **Devise統合**: ジェネレータ→カスタム追加の明確な流れ
- **PostgreSQL対応**: Alpine版制約（英語辞書）考慮
- **JSONB統一**: GINインデックス対応設計

## マイグレーション作成順序 v2.0

### Phase 1: Devise導入と基盤テーブル

#### 1. **Devise導入とadmin_usersベース生成**
```bash
# Devise導入
rails generate devise:install
rails generate devise AdminUser

# 生成されるマイグレーション
# → 001_devise_create_admin_users.rb
```

#### 2. **002_add_custom_fields_to_admin_users.rb**
```ruby
class AddCustomFieldsToAdminUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :admin_users, :name, :string, null: false
    add_column :admin_users, :avatar_url, :string
    add_column :admin_users, :role, :string, default: 'author'
    add_column :admin_users, :settings, :jsonb, default: {}
    add_column :admin_users, :api_token, :string
    
    # 2FA設定
    add_column :admin_users, :otp_secret, :string
    add_column :admin_users, :otp_required_for_login, :boolean, default: false
    
    # アクセス制御（Deviseで自動追加されない場合）
    add_column :admin_users, :failed_attempts, :integer, default: 0
    add_column :admin_users, :locked_at, :datetime
    
    # 手動インデックス（複合・特殊用途のみ）
    add_index :admin_users, :role
    add_index :admin_users, :api_token, unique: true
    
    # 制約
    add_check_constraint :admin_users, "role IN ('admin', 'editor', 'author', 'viewer')", 
                        name: 'admin_users_valid_role'
  end
end
```

#### 3. **003_create_sections.rb**
```ruby
class CreateSections < ActiveRecord::Migration[8.0]
  def change
    create_table :sections do |t|
      t.string :name, null: false, index: { unique: true }
      t.string :display_name, null: false
      t.boolean :is_visible, default: true
      t.integer :position, default: 0
      
      t.timestamps
    end
    
    add_index :sections, :position
  end
end
```

#### 4. **004_create_settings.rb**
```ruby
class CreateSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :settings do |t|
      t.string :key, null: false, index: { unique: true }
      t.text :value
      t.string :value_type, default: 'string'
      t.string :category, null: false
      t.text :description
      t.boolean :is_sensitive, default: false
      t.jsonb :json_value, default: {}
      
      t.timestamps
    end
    
    # 手動インデックス（クエリ最適化用）
    add_index :settings, :category
    add_index :settings, :json_value, using: :gin
    
    # 制約
    add_check_constraint :settings, 
                        "value_type IN ('string', 'integer', 'boolean', 'jsonb')",
                        name: 'settings_valid_value_type'
  end
end
```

### Phase 2: 独立系テーブル

#### 5. **005_create_tags.rb**
```ruby
class CreateTags < ActiveRecord::Migration[8.0]
  def change
    create_table :tags do |t|
      t.string :name, null: false, index: { unique: true }
      t.string :slug, null: false, index: { unique: true }
      t.integer :article_count, default: 0
      
      t.timestamps
    end
  end
end
```

#### 6. **006_create_categories.rb**
```ruby
class CreateCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :categories do |t|
      # 自己参照外部キー（Rails 8.0が自動でインデックス作成）
      t.references :parent, null: true, foreign_key: { to_table: :categories }
      
      t.string :name, null: false, limit: 100
      t.string :slug, null: false, limit: 100
      t.text :description
      t.string :icon, limit: 50
      t.string :color, limit: 7
      t.integer :position, default: 0
      t.integer :article_count, default: 0
      
      t.timestamps
    end
    
    # 複合インデックス（階層スラッグの一意性確保）
    add_index :categories, [:slug, :parent_id], unique: true
    add_index :categories, :position
  end
end
```

### Phase 3: コアコンテンツテーブル

#### 7. **007_create_articles.rb**
```ruby
class CreateArticles < ActiveRecord::Migration[8.0]
  def change
    create_table :articles do |t|
      # 外部キー（Rails 8.0が自動でインデックス作成）
      t.references :admin_user, null: false, foreign_key: true
      
      t.string :title, null: false
      t.string :slug, null: false, index: { unique: true }
      t.text :content, null: false
      t.text :content_html
      t.text :excerpt
      
      # ステータス管理
      t.string :status, default: 'draft', null: false
      t.datetime :published_at
      
      # SEO設定
      t.string :meta_description, limit: 500
      t.string :meta_keywords, limit: 500
      t.string :og_title
      t.string :og_description, limit: 500
      t.string :og_image_url, limit: 500
      
      # 統計
      t.integer :view_count, default: 0
      t.integer :comment_count, default: 0
      t.integer :reading_time
      
      # AI分析結果
      t.text :ai_summary
      t.text :ai_keywords
      t.decimal :ai_seo_score, precision: 3, scale: 2
      
      # バージョン管理
      t.integer :revision_count, default: 0
      
      # 全文検索用（PostgreSQL Alpine = 英語辞書）
      t.tsvector :search_vector
      
      t.timestamps
    end
    
    # 手動インデックス（パフォーマンス最適化）
    add_index :articles, :search_vector, using: :gin
    add_index :articles, [:status, :published_at], 
              where: "status = 'published'"
    
    # 制約
    add_check_constraint :articles, 
                        "status IN ('draft', 'published', 'scheduled', 'archived')",
                        name: 'articles_valid_status'
  end
end
```

#### 8. **008_create_media_files.rb**
```ruby
class CreateMediaFiles < ActiveRecord::Migration[8.0]
  def change
    create_table :media_files do |t|
      # 外部キー（Rails 8.0が自動でインデックス作成）
      t.references :admin_user, null: false, foreign_key: true
      
      # ファイル情報
      t.string :filename, null: false
      t.string :original_filename, null: false
      t.string :content_type, null: false
      t.bigint :file_size, null: false
      
      # ストレージ情報
      t.string :storage_path, null: false, limit: 500
      t.string :storage_provider, default: 'local'
      t.string :cdn_url, limit: 500
      
      # 画像専用情報
      t.integer :width
      t.integer :height
      t.string :thumbnail_path, limit: 500
      t.string :webp_path, limit: 500
      
      # メタデータ
      t.string :alt_text
      t.text :caption
      
      # 使用統計
      t.integer :usage_count, default: 0
      t.datetime :last_used_at
      
      t.timestamps
    end
    
    # 手動インデックス（クエリ最適化）
    add_index :media_files, :content_type
    add_index :media_files, :created_at
  end
end
```

#### 9. **009_create_section_contents.rb**
```ruby
class CreateSectionContents < ActiveRecord::Migration[8.0]
  def change
    create_table :section_contents do |t|
      # 外部キー（Rails 8.0が自動でインデックス作成）
      t.references :section, null: false, foreign_key: true
      
      # JSONBでフレキシブルなコンテンツ管理
      t.jsonb :content, null: false, default: {}
      
      # バージョン管理
      t.integer :version, null: false, default: 1
      t.boolean :is_active, default: false
      t.references :published_by, foreign_key: { to_table: :admin_users }
      t.datetime :published_at
      
      t.timestamps
    end
    
    # 手動インデックス（複合・JSONB）
    add_index :section_contents, [:section_id, :is_active]
    add_index :section_contents, [:section_id, :version]
    add_index :section_contents, :content, using: :gin
  end
end
```

### Phase 4: 関連・中間テーブル

#### 10. **010_create_article_categories.rb**
```ruby
class CreateArticleCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :article_categories, primary_key: [:article_id, :category_id] do |t|
      # 複合主キー（Rails 8.0が自動で外部キーインデックス作成）
      t.references :article, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      
      t.boolean :is_primary, default: false
      t.datetime :created_at, null: false, default: -> { 'NOW()' }
    end
    
    # 手動インデックス（クエリ最適化）
    add_index :article_categories, :category_id, 
              where: 'is_primary = true',
              name: 'index_article_categories_primary'
  end
end
```

#### 11. **011_create_article_tags.rb**
```ruby
class CreateArticleTags < ActiveRecord::Migration[8.0]
  def change
    create_table :article_tags, primary_key: [:article_id, :tag_id] do |t|
      # 複合主キー（Rails 8.0が自動で外部キーインデックス作成）
      t.references :article, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true
      
      t.datetime :created_at, null: false, default: -> { 'NOW()' }
    end
    
    # 複合主キーがあるため追加インデックス不要
  end
end
```

#### 12. **012_create_article_media.rb**
```ruby
class CreateArticleMedia < ActiveRecord::Migration[8.0]
  def change
    create_table :article_media, primary_key: [:article_id, :media_file_id] do |t|
      # 複合主キー（Rails 8.0が自動で外部キーインデックス作成）
      t.references :article, null: false, foreign_key: true
      t.references :media_file, null: false, foreign_key: true
      
      t.integer :position, default: 0
      t.datetime :created_at, null: false, default: -> { 'NOW()' }
    end
    
    # 複合主キーがあるため追加インデックス不要
  end
end
```

### Phase 5: コメント・お問い合わせ

#### 13. **013_create_comments.rb**
```ruby
class CreateComments < ActiveRecord::Migration[8.0]
  def change
    create_table :comments do |t|
      # 外部キー（Rails 8.0が自動でインデックス作成）
      t.references :article, null: false, foreign_key: true
      t.references :parent, null: true, foreign_key: { to_table: :comments }
      
      # 投稿者情報
      t.string :author_name, null: false, limit: 100
      t.string :author_email, null: false
      t.string :author_url, limit: 500
      t.inet :author_ip
      t.text :author_user_agent
      
      # コメント内容
      t.text :content, null: false
      t.text :content_html
      
      # ステータス
      t.string :status, default: 'pending', null: false
      
      # モデレーション
      t.references :moderated_by, foreign_key: { to_table: :admin_users }
      t.datetime :moderated_at
      t.decimal :spam_score, precision: 3, scale: 2, default: 0.0
      
      t.timestamps
    end
    
    # 手動インデックス（クエリ最適化）
    add_index :comments, :status
    add_index :comments, :author_email
    add_index :comments, [:article_id, :status, :created_at]
    
    # 制約
    add_check_constraint :comments, 
                        "status IN ('pending', 'approved', 'spam', 'trash')",
                        name: 'comments_valid_status'
  end
end
```

#### 14. **014_create_contacts.rb**
```ruby
class CreateContacts < ActiveRecord::Migration[8.0]
  def change
    create_table :contacts do |t|
      # 送信者情報
      t.string :name, null: false, limit: 100
      t.string :email, null: false
      t.string :subject, null: false
      t.text :message, null: false
      
      # メタデータ
      t.inet :ip_address
      t.text :user_agent
      t.string :referrer, limit: 500
      
      # ステータス
      t.string :status, default: 'unread', null: false
      
      # 対応情報
      t.references :assigned_to, foreign_key: { to_table: :admin_users }
      t.datetime :replied_at
      t.text :notes
      
      # スパムチェック
      t.decimal :spam_score, precision: 3, scale: 2
      t.boolean :is_spam, default: false
      
      t.timestamps
    end
    
    # 手動インデックス
    add_index :contacts, :email
    add_index :contacts, :status
    add_index :contacts, :created_at
    
    # 制約
    add_check_constraint :contacts, 
                        "status IN ('unread', 'read', 'replied', 'archived')",
                        name: 'contacts_valid_status'
  end
end
```

### Phase 6: 拡張機能テーブル

#### 15. **015_create_article_revisions.rb**
```ruby
class CreateArticleRevisions < ActiveRecord::Migration[8.0]
  def change
    create_table :article_revisions do |t|
      # 外部キー（Rails 8.0が自動でインデックス作成）
      t.references :article, null: false, foreign_key: true
      t.references :admin_user, null: false, foreign_key: true
      
      # リビジョンデータ
      t.string :title, null: false
      t.text :content, null: false
      
      # 変更情報
      t.integer :revision_number, null: false
      t.string :change_summary, limit: 500
      
      # メタデータ（JSONB統一）
      t.jsonb :metadata, default: {}
      
      t.datetime :created_at, null: false, default: -> { 'NOW()' }
    end
    
    # 手動インデックス（複合・JSONB）
    add_index :article_revisions, [:article_id, :revision_number], unique: true
    add_index :article_revisions, :created_at
    add_index :article_revisions, :metadata, using: :gin
  end
end
```

#### 16. **016_create_article_ai_analyses.rb**
```ruby
class CreateArticleAiAnalyses < ActiveRecord::Migration[8.0]
  def change
    create_table :article_ai_analyses do |t|
      # 外部キー（Rails 8.0が自動でインデックス作成）
      t.references :article, null: false, foreign_key: true, index: { unique: true }
      
      # AI生成コンテンツ
      t.text :summary
      t.text :keywords
      t.text :related_topics
      
      # SEO分析（JSONB統一）
      t.decimal :seo_score, precision: 3, scale: 2
      t.jsonb :seo_suggestions, default: {}
      t.decimal :readability_score, precision: 3, scale: 2
      
      # 感情分析
      t.string :sentiment, limit: 50
      t.string :tone, limit: 50
      
      # API情報（JSONB統一）
      t.jsonb :api_metadata, default: {}
      
      t.datetime :analyzed_at, null: false, default: -> { 'NOW()' }
    end
    
    # 手動インデックス（JSONB）
    add_index :article_ai_analyses, :seo_suggestions, using: :gin
    add_index :article_ai_analyses, :api_metadata, using: :gin
  end
end
```

### Phase 7: 通知・ログ管理

#### 17. **017_create_slack_notifications.rb**
```ruby
class CreateSlackNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :slack_notifications do |t|
      # 通知情報
      t.string :notification_type, null: false, limit: 50
      t.bigint :reference_id
      t.string :reference_type, limit: 50
      
      # Slack情報
      t.string :webhook_url, limit: 500
      t.string :channel, limit: 100
      
      # 送信内容（JSONB統一）
      t.jsonb :payload, null: false, default: {}
      
      # ステータス
      t.string :status, default: 'pending', null: false
      t.text :error_message
      t.integer :retry_count, default: 0
      
      t.datetime :created_at, null: false, default: -> { 'NOW()' }
      t.datetime :sent_at
    end
    
    # 手動インデックス
    add_index :slack_notifications, :notification_type
    add_index :slack_notifications, :status
    add_index :slack_notifications, :created_at
    add_index :slack_notifications, :payload, using: :gin
    
    # 制約
    add_check_constraint :slack_notifications, 
                        "notification_type IN ('contact', 'article_published', 'comment', 'error')",
                        name: 'slack_notifications_valid_type'
  end
end
```

#### 18. **018_create_access_logs.rb**
```ruby
class CreateAccessLogs < ActiveRecord::Migration[8.0]
  def up
    # パーティション親テーブル
    execute <<-SQL
      CREATE TABLE access_logs (
        id BIGSERIAL,
        path VARCHAR(500) NOT NULL,
        method VARCHAR(10) NOT NULL,
        status_code INTEGER,
        ip_address INET,
        user_agent TEXT,
        referrer VARCHAR(500),
        response_time INTEGER,
        admin_user_id BIGINT,
        session_id VARCHAR(255),
        created_at TIMESTAMP NOT NULL DEFAULT NOW(),
        PRIMARY KEY (id, created_at)
      ) PARTITION BY RANGE (created_at);
    SQL
    
    # 初期パーティション作成（現在月）
    current_month = Date.current.beginning_of_month
    next_month = current_month.next_month
    partition_name = "access_logs_#{current_month.strftime('%Y_%m')}"
    
    execute <<-SQL
      CREATE TABLE #{partition_name} PARTITION OF access_logs
      FOR VALUES FROM ('#{current_month}') TO ('#{next_month}');
    SQL
    
    # パーティション用インデックス
    add_index partition_name, :created_at
    add_index partition_name, :path
    add_index partition_name, :admin_user_id
    
    # 外部キー制約（パーティション子テーブルに追加）
    execute <<-SQL
      ALTER TABLE #{partition_name} 
      ADD CONSTRAINT fk_#{partition_name}_admin_user 
      FOREIGN KEY (admin_user_id) REFERENCES admin_users(id);
    SQL
  end
  
  def down
    drop_table :access_logs
  end
end
```

#### 19. **019_create_backups.rb**
```ruby
class CreateBackups < ActiveRecord::Migration[8.0]
  def change
    create_table :backups do |t|
      # バックアップ情報
      t.string :backup_type, null: false, limit: 50
      t.string :status, null: false, limit: 50
      
      # ファイル情報
      t.string :filename
      t.bigint :file_size
      t.string :storage_location, limit: 500
      
      # 統計
      t.integer :duration_seconds
      t.integer :tables_count
      t.integer :records_count
      
      # エラー情報
      t.text :error_message
      
      # タイムスタンプ
      t.datetime :started_at, null: false
      t.datetime :completed_at
    end
    
    # 手動インデックス
    add_index :backups, :backup_type
    add_index :backups, :status
    add_index :backups, :started_at
    
    # 制約
    add_check_constraint :backups, 
                        "backup_type IN ('full', 'incremental', 'database', 'media')",
                        name: 'backups_valid_type'
    add_check_constraint :backups, 
                        "status IN ('running', 'completed', 'failed')",
                        name: 'backups_valid_status'
  end
end
```

### Phase 8: インデックス・トリガー・関数

#### 20. **020_create_database_functions.rb**
```ruby
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
  end
  
  def down
    execute "DROP TRIGGER IF EXISTS update_articles_search_vector ON articles;"
    execute "DROP TRIGGER IF EXISTS trigger_update_category_count ON article_categories;"
    execute "DROP TRIGGER IF EXISTS trigger_update_media_usage ON article_media;"
    
    execute "DROP FUNCTION IF EXISTS update_category_article_count();"
    execute "DROP FUNCTION IF EXISTS update_media_usage();"
    execute "DROP FUNCTION IF EXISTS create_monthly_partition();"
  end
end
```

## Rails 8.0対応設計のポイント

### ✅ Rails 8.0活用事項

#### **外部キー自動インデックス**
```ruby
# 良い例: Rails 8.0が自動でインデックス作成
t.references :admin_user, null: false, foreign_key: true
# → 自動生成: index_articles_on_admin_user_id

# 悪い例: 重複インデックス作成
t.references :admin_user, null: false, foreign_key: true
add_index :articles, :admin_user_id # ← 不要！
```

#### **JSONB統一でGINインデックス活用**
```ruby
# 良い例: JSONBでGINインデックス対応
t.jsonb :settings, default: {}
add_index :admin_users, :settings, using: :gin

# 避ける例: JSONではGINインデックス不可
t.json :settings # ← GINインデックスが使えない
```

### ✅ PostgreSQL Alpine制約対応

#### **英語辞書使用**
```sql
-- 良い例: Alpine PostgreSQLで利用可能
tsvector_update_trigger(search_vector, 'pg_catalog.english', title, content)

-- 避ける例: Alpine PostgreSQLで未対応
tsvector_update_trigger(search_vector, 'pg_catalog.japanese', title, content)
```

### ✅ Devise統合ベストプラクティス

#### **段階的カスタムフィールド追加**
```ruby
# Step 1: Devise標準生成
rails generate devise AdminUser

# Step 2: カスタムフィールド追加マイグレーション
class AddCustomFieldsToAdminUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :admin_users, :name, :string, null: false
    add_column :admin_users, :role, :string, default: 'author'
    # ... その他のカスタムフィールド
  end
end
```

## パフォーマンス最適化戦略

### **部分インデックス活用**
```ruby
# 公開記事のみインデックス
add_index :articles, [:status, :published_at], 
          where: "status = 'published'"

# 主カテゴリのみインデックス
add_index :article_categories, :category_id, 
          where: 'is_primary = true'
```

### **同時実行インデックス作成**
```ruby
class AddSearchIndexesConcurrently < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!
  
  def change
    add_index :articles, :search_vector, 
              using: :gin, 
              algorithm: :concurrently
  end
end
```

### **パーティショニング戦略**
```ruby
# 月次パーティション自動作成
# crontabまたはpg_cronで定期実行
# 0 0 1 * * SELECT create_monthly_partition();
```

## 注意事項・制約

### **Rails 8.0対応**
1. **外部キー自動インデックス**: 重複作成回避
2. **制約命名**: Rails標準命名規則に従う
3. **JSONB統一**: 複雑データ構造にはJSONB使用

### **PostgreSQL制約**
1. **Alpine版制約**: 英語辞書のみ使用可能
2. **パーティション**: 月次分割でパフォーマンス最適化
3. **GINインデックス**: JSONBのみ対応

### **Devise統合**
1. **テーブル名統一**: admin_usersで統一
2. **段階的追加**: Devise生成→カスタムフィールド追加
3. **標準機能活用**: Deviseの認証・認可機能最大活用

### **実装順序厳守**
1. **依存関係**: 外部キー制約を考慮した順序
2. **ロールバック対応**: down メソッド実装必須
3. **初期データ**: seeds.rb で一元管理

---

**🎯 この実装計画v2.0では、Rails 8.0の機能を最大限活用し、PostgreSQL環境制約に適応し、Devise統合を明確化した効率的なマイグレーション戦略を提供します。**