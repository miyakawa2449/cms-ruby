# Railsマイグレーション実装計画

## 概要
スキーマ設計に基づいたRailsマイグレーションファイルの作成順序と実装計画。

## マイグレーション作成順序

### Phase 1: 基盤テーブル（独立系）

1. **001_create_admin_users.rb**
   - Devise導入後に自動生成されるものをカスタマイズ
   - 2FA、ロール、アクセス制御フィールド追加

2. **002_create_sections.rb**
   - ポートフォリオの基本セクション定義
   - 初期データ投入も含む

3. **003_create_settings.rb**
   - システム設定テーブル
   - 初期設定値の投入

4. **004_create_tags.rb**
   - タグマスタテーブル

### Phase 2: コアコンテンツテーブル

5. **005_create_categories.rb**
   - 階層カテゴリ対応（自己参照）
   - 親子関係のインデックス

6. **006_create_articles.rb**
   - ブログ記事メインテーブル
   - 全文検索設定含む

7. **007_create_media_files.rb**
   - メディアファイル管理

8. **008_create_section_contents.rb**
   - セクションコンテンツ（JSONB使用）

### Phase 3: 関連・中間テーブル

9. **009_create_article_categories.rb**
   - 記事-カテゴリ多対多

10. **010_create_article_tags.rb**
    - 記事-タグ多対多

11. **011_create_article_media.rb**
    - 記事-メディア多対多

12. **012_create_comments.rb**
    - コメント（記事に依存）

13. **013_create_contacts.rb**
    - お問い合わせ

### Phase 4: 拡張機能テーブル

14. **014_create_article_revisions.rb**
    - 記事リビジョン管理

15. **015_create_article_ai_analyses.rb**
    - AI分析結果保存

16. **016_create_slack_notifications.rb**
    - Slack通知履歴

17. **017_create_access_logs.rb**
    - アクセスログ（パーティション対応）

18. **018_create_backups.rb**
    - バックアップ履歴

### Phase 5: インデックス・トリガー・関数

19. **019_add_search_indexes.rb**
    - 全文検索インデックス
    - 複合インデックス

20. **020_create_database_functions.rb**
    - カウント更新関数
    - パーティション作成関数
    - トリガー設定

## 実装のポイント

### 1. Devise連携
```ruby
# admin_users テーブルはDevise導入時に生成されるため、追加カラムは別マイグレーションで
class AddCustomFieldsToAdminUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :admin_users, :name, :string, null: false
    add_column :admin_users, :avatar_url, :string
    add_column :admin_users, :role, :string, default: 'admin' # 権限: admin, editor, author, viewer
    add_column :admin_users, :otp_secret, :string
    add_column :admin_users, :otp_required_for_login, :boolean, default: false
    add_column :admin_users, :failed_attempts, :integer, default: 0
    add_column :admin_users, :locked_at, :datetime
    
    add_index :admin_users, :role
  end
end
```

### 2. PostgreSQL特有機能の活用
```ruby
# 全文検索の設定
class AddFullTextSearchToArticles < ActiveRecord::Migration[7.1]
  def up
    # tsvector カラム追加
    add_column :articles, :search_vector, :tsvector
    add_index :articles, :search_vector, using: :gin
    
    # 自動更新トリガー
    execute <<-SQL
      CREATE TRIGGER update_articles_search_vector 
      BEFORE INSERT OR UPDATE ON articles 
      FOR EACH ROW EXECUTE FUNCTION 
      tsvector_update_trigger(search_vector, 'pg_catalog.japanese', title, content, excerpt);
    SQL
  end
  
  def down
    remove_column :articles, :search_vector
  end
end
```

### 3. JSONB活用
```ruby
class CreateSectionContents < ActiveRecord::Migration[7.1]
  def change
    create_table :section_contents do |t|
      t.references :section, null: false, foreign_key: true
      t.jsonb :content, null: false, default: {}
      t.integer :version, null: false, default: 1
      t.boolean :is_active, default: false
      t.references :published_by, foreign_key: { to_table: :admin_users }
      t.datetime :published_at
      
      t.timestamps
      
      t.index [:section_id, :is_active]
      t.index [:section_id, :version]
    end
  end
end
```

### 4. パーティショニング
```ruby
class CreateAccessLogs < ActiveRecord::Migration[7.1]
  def change
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
        admin_user_id BIGINT REFERENCES admin_users(id),
        session_id VARCHAR(255),
        created_at TIMESTAMP NOT NULL DEFAULT NOW(),
        PRIMARY KEY (id, created_at)
      ) PARTITION BY RANGE (created_at);
    SQL
    
    # 初期パーティション作成
    current_month = Date.current.beginning_of_month
    next_month = current_month.next_month
    
    execute <<-SQL
      CREATE TABLE access_logs_#{current_month.strftime('%Y_%m')} 
      PARTITION OF access_logs
      FOR VALUES FROM ('#{current_month}') TO ('#{next_month}');
    SQL
    
    # インデックス作成
    add_index "access_logs_#{current_month.strftime('%Y_%m')}", :created_at
    add_index "access_logs_#{current_month.strftime('%Y_%m')}", :path
    add_index "access_logs_#{current_month.strftime('%Y_%m')}", :admin_user_id
  end
end
```

### 5. カスタムトリガー
```ruby
class CreateDatabaseFunctions < ActiveRecord::Migration[7.1]
  def up
    # カテゴリ記事数更新
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
  end
  
  def down
    execute "DROP TRIGGER IF EXISTS trigger_update_category_count ON article_categories;"
    execute "DROP FUNCTION IF EXISTS update_category_article_count();"
  end
end
```

## モデル設定例

### Article モデル
```ruby
class Article < ApplicationRecord
  belongs_to :admin_user
  has_many :article_categories, dependent: :destroy
  has_many :categories, through: :article_categories
  has_many :article_tags, dependent: :destroy
  has_many :tags, through: :article_tags
  has_many :comments, dependent: :destroy
  has_many :article_media, dependent: :destroy
  has_many :media_files, through: :article_media
  has_many :revisions, class_name: 'ArticleRevision', dependent: :destroy
  has_one :ai_analysis, class_name: 'ArticleAiAnalysis', dependent: :destroy
  
  # 全文検索
  include PgSearch::Model
  pg_search_scope :search_full_text,
                  against: {
                    title: 'A',
                    content: 'B',
                    excerpt: 'C'
                  },
                  using: {
                    tsearch: {
                      dictionary: 'japanese',
                      tsvector_column: 'search_vector'
                    }
                  }
  
  # ステータス
  enum status: {
    draft: 'draft',
    published: 'published',
    scheduled: 'scheduled',
    archived: 'archived'
  }
  
  # バリデーション
  validates :title, presence: true, length: { maximum: 255 }
  validates :slug, presence: true, uniqueness: true
  validates :content, presence: true
  
  # コールバック
  before_validation :generate_slug, if: :title_changed?
  after_save :update_revision
  after_save :enqueue_ai_analysis, if: :published?
  
  private
  
  def generate_slug
    self.slug = title.parameterize if title.present?
  end
  
  def update_revision
    revisions.create!(
      admin_user: admin_user,
      title: title,
      content: content,
      revision_number: revision_count + 1
    )
    increment!(:revision_count)
  end
  
  def enqueue_ai_analysis
    ArticleAiAnalysisJob.perform_later(self)
  end
end
```

### Category モデル（階層対応）
```ruby
class Category < ApplicationRecord
  has_many :children, class_name: 'Category', foreign_key: 'parent_id'
  belongs_to :parent, class_name: 'Category', optional: true
  has_many :article_categories, dependent: :restrict_with_error
  has_many :articles, through: :article_categories
  
  # バリデーション
  validates :name, presence: true, length: { maximum: 100 }
  validates :slug, presence: true, uniqueness: { scope: :parent_id }
  validate :validate_hierarchy_depth
  
  # スコープ
  scope :root_categories, -> { where(parent_id: nil) }
  scope :ordered, -> { order(position: :asc) }
  
  # 階層パスを取得
  def full_path
    parent ? "#{parent.slug}/#{slug}" : slug
  end
  
  def full_name
    parent ? "#{parent.name} / #{name}" : name
  end
  
  private
  
  def validate_hierarchy_depth
    if parent&.parent_id.present?
      errors.add(:parent_id, 'カテゴリは2階層までです')
    end
  end
end
```

## API対応確認結果

### ✅ 既存20マイグレーションで完全対応
**結論**: API機能実装に**追加マイグレーション不要**

#### API機能カバレッジ
- **JWT認証**: admin_users + settings テーブルで対応
- **API統計**: access_logs テーブル（パーティション対応）で完全対応
- **AI API**: article_ai_analyses テーブルで完全対応
- **メディアAPI**: media_files テーブルで完全対応
- **検索API**: articles.search_vector で完全対応
- **通知API**: slack_notifications + contacts テーブルで完全対応
- **ポートフォリオAPI**: section_contents.content JSONB で完全対応

#### API用初期データのみ追加（seeds.rb）
```ruby
# API設定の初期化
api_settings = [
  {key: 'jwt_secret_key', value: SecureRandom.hex(32), category: 'api', is_sensitive: true},
  {key: 'api_rate_limit_global', value: '300', category: 'api'},
  {key: 'cors_allowed_origins', value: 'https://example.test', category: 'api'}
]
```

詳細分析: `docs/api/migration_gap_analysis.md`

## 注意事項

1. **マイグレーション順序厳守**: 外部キー制約があるため順序は重要
2. **ロールバック対応**: down メソッドも必ず実装
3. **インデックス命名規則**: Rails標準に従う
4. **初期データ**: seeds.rb で管理（API設定含む）
5. **環境別設定**: development/staging/production で異なる設定は environment.rb で管理
6. **API対応**: 既存テーブル設計で100%カバー、追加テーブル不要