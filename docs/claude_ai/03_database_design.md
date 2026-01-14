# データベース設計仕様書

## データベース概要

### 使用データベース
- **DBMS**: PostgreSQL 17-alpine (Docker環境)
- **特徴**: ICUロケール対応、JSONB型活用、GINインデックス
- **文字エンコーディング**: UTF-8
- **タイムゾーン**: Asia/Tokyo

### 総テーブル数
20テーブル（Active Storage含む）

## 主要テーブル仕様

### 1. admin_users（管理者）

| カラム名 | 型 | 制約 | 説明 |
|---------|-----|------|------|
| id | bigint | PRIMARY KEY | ID |
| email | string | NOT NULL, UNIQUE | メールアドレス |
| encrypted_password | string | NOT NULL | 暗号化パスワード |
| reset_password_token | string | INDEX | パスワードリセットトークン |
| reset_password_sent_at | datetime | | リセット送信日時 |
| remember_created_at | datetime | | Remember me日時 |
| created_at | datetime | NOT NULL | 作成日時 |
| updated_at | datetime | NOT NULL | 更新日時 |

**関連**:
- has_many :articles
- has_many :published_section_contents

### 2. articles（記事）

| カラム名 | 型 | 制約 | 説明 |
|---------|-----|------|------|
| id | bigint | PRIMARY KEY | ID |
| admin_user_id | bigint | NOT NULL, FK | 作成者ID |
| title | string(255) | NOT NULL | タイトル |
| slug | string(255) | NOT NULL, UNIQUE | URL用スラッグ |
| content | text | NOT NULL | 本文（Markdown） |
| excerpt | text | | 抜粋 |
| status | string | DEFAULT 'draft' | 公開状態 |
| published_at | datetime | | 公開日時 |
| meta_description | string(500) | | メタディスクリプション |
| meta_keywords | string(500) | | メタキーワード |
| og_title | string(255) | | OGPタイトル |
| og_description | string(500) | | OGP説明 |
| og_image | string(500) | | OGP画像URL |
| work_type | string | | 作品タイプ（Works用） |
| github_url | string | | GitHubリポジトリURL |
| demo_url | string | | デモURL |
| tech_stack | text | | 技術スタック |
| view_count | integer | DEFAULT 0 | 閲覧数 |
| created_at | datetime | NOT NULL | 作成日時 |
| updated_at | datetime | NOT NULL | 更新日時 |

**インデックス**:
- `index_articles_on_slug` (UNIQUE)
- `index_articles_on_admin_user_id`
- `index_articles_on_status`
- `index_articles_on_published_at`

**関連**:
- belongs_to :admin_user
- has_many :article_categories
- has_many :categories, through: :article_categories
- has_many :article_tags
- has_many :tags, through: :article_tags
- has_one_attached :thumbnail_image

### 3. categories（カテゴリ）

| カラム名 | 型 | 制約 | 説明 |
|---------|-----|------|------|
| id | bigint | PRIMARY KEY | ID |
| parent_id | bigint | FK (self) | 親カテゴリID |
| name | string(100) | NOT NULL, UNIQUE | カテゴリ名 |
| slug | string(100) | NOT NULL, UNIQUE | URLスラッグ |
| description | text | | 説明 |
| icon | string(50) | | アイコン名 |
| color | string(7) | | カラーコード |
| position | integer | DEFAULT 0 | 表示順 |
| article_count | integer | DEFAULT 0 | 記事数 |
| created_at | datetime | NOT NULL | 作成日時 |
| updated_at | datetime | NOT NULL | 更新日時 |

**インデックス**:
- `index_categories_on_name` (UNIQUE)
- `index_categories_on_slug` (UNIQUE)
- `index_categories_on_parent_id`
- `index_categories_on_position`

**関連**:
- belongs_to :parent, class_name: 'Category', optional: true
- has_many :children, class_name: 'Category', foreign_key: 'parent_id'
- has_many :article_categories
- has_many :articles, through: :article_categories

### 4. tags（タグ）

| カラム名 | 型 | 制約 | 説明 |
|---------|-----|------|------|
| id | bigint | PRIMARY KEY | ID |
| name | string(50) | NOT NULL, UNIQUE | タグ名 |
| slug | string(50) | NOT NULL, UNIQUE | URLスラッグ |
| article_count | integer | DEFAULT 0 | 記事数 |
| created_at | datetime | NOT NULL | 作成日時 |
| updated_at | datetime | NOT NULL | 更新日時 |

**インデックス**:
- `index_tags_on_name` (UNIQUE)
- `index_tags_on_slug` (UNIQUE)

### 5. sections（セクション）

| カラム名 | 型 | 制約 | 説明 |
|---------|-----|------|------|
| id | bigint | PRIMARY KEY | ID |
| name | string(100) | NOT NULL, UNIQUE | セクション名（内部用） |
| display_name | string(100) | NOT NULL | 表示名 |
| is_visible | boolean | DEFAULT true | 表示フラグ |
| position | integer | DEFAULT 0 | 表示順 |
| created_at | datetime | NOT NULL | 作成日時 |
| updated_at | datetime | NOT NULL | 更新日時 |

**デフォルトセクション**:
- hero（ヒーローセクション）
- about（About）
- service（Service）
- my_story（My Story）
- works（Works）
- blog（Blog）
- contact（Contact）
- footer（フッター）

### 6. section_contents（セクションコンテンツ）

| カラム名 | 型 | 制約 | 説明 |
|---------|-----|------|------|
| id | bigint | PRIMARY KEY | ID |
| section_id | bigint | NOT NULL, FK | セクションID |
| content | jsonb | NOT NULL, DEFAULT '{}' | JSONBコンテンツ |
| version | integer | NOT NULL, DEFAULT 1 | バージョン番号 |
| is_active | boolean | DEFAULT false | アクティブフラグ |
| published_by | bigint | FK | 公開者ID |
| published_at | datetime | | 公開日時 |
| [各種フィールド] | text/string | | セクション別フィールド |
| created_at | datetime | NOT NULL | 作成日時 |
| updated_at | datetime | NOT NULL | 更新日時 |

**インデックス**:
- `index_section_contents_on_section_id_and_version` (UNIQUE)
- `index_section_contents_on_content` (GIN)

### 7. contacts（お問い合わせ）

| カラム名 | 型 | 制約 | 説明 |
|---------|-----|------|------|
| id | bigint | PRIMARY KEY | ID |
| name | string | NOT NULL | 名前 |
| email | string | NOT NULL | メールアドレス |
| subject | string | | 件名 |
| message | text | NOT NULL | メッセージ |
| ip_address | inet | | IPアドレス |
| user_agent | text | | ユーザーエージェント |
| referrer | string | | リファラ |
| status | string | DEFAULT 'unread' | ステータス |
| assigned_to_id | bigint | FK | 担当者ID |
| replied_at | datetime | | 返信日時 |
| notes | text | | 管理者メモ |
| spam_score | decimal(3,2) | | スパムスコア |
| is_spam | boolean | DEFAULT false | スパムフラグ |
| created_at | datetime | NOT NULL | 作成日時 |
| updated_at | datetime | NOT NULL | 更新日時 |

### 8. my_story_sections（My Storyセクション）

| カラム名 | 型 | 制約 | 説明 |
|---------|-----|------|------|
| id | bigint | PRIMARY KEY | ID |
| section_type | string | NOT NULL, UNIQUE | セクションタイプ |
| title | string | NOT NULL | タイトル |
| subtitle | string | | サブタイトル |
| content | text | | 内容 |
| position | integer | NOT NULL, DEFAULT 0 | 表示順 |
| is_active | boolean | NOT NULL, DEFAULT true | 有効フラグ |
| additional_data | jsonb | DEFAULT '{}' | 追加データ |
| skills | text | | スキル |
| achievements | text | | 実績 |
| quote | text | | 引用 |
| created_at | datetime | NOT NULL | 作成日時 |
| updated_at | datetime | NOT NULL | 更新日時 |

## 中間テーブル

### article_categories（記事-カテゴリ）
| カラム名 | 型 | 制約 | 説明 |
|---------|-----|------|------|
| article_id | bigint | NOT NULL, FK | 記事ID |
| category_id | bigint | NOT NULL, FK | カテゴリID |
| is_primary | boolean | DEFAULT false | 主カテゴリフラグ |
| created_at | datetime | NOT NULL | 作成日時 |

**主キー**: (article_id, category_id)

### article_tags（記事-タグ）
| カラム名 | 型 | 制約 | 説明 |
|---------|-----|------|------|
| article_id | bigint | NOT NULL, FK | 記事ID |
| tag_id | bigint | NOT NULL, FK | タグID |
| created_at | datetime | NOT NULL | 作成日時 |

**主キー**: (article_id, tag_id)

## Active Storageテーブル

### active_storage_blobs（ファイル情報）
- ファイル名、コンテンツタイプ、サイズ等を管理

### active_storage_attachments（添付関連）
- ポリモーフィック関連でモデルとBlobを紐付け

### active_storage_variant_records（バリアント）
- 画像のリサイズ版等を管理

## システムテーブル

### site_settings（サイト設定）
| カラム名 | 型 | 制約 | 説明 |
|---------|-----|------|------|
| id | bigint | PRIMARY KEY | ID |
| key | string | NOT NULL, UNIQUE | 設定キー |
| value | text | | 設定値 |
| setting_type | string | DEFAULT 'text' | 設定タイプ |
| description | text | | 説明 |

### slack_notifications（Slack通知履歴）
| カラム名 | 型 | 制約 | 説明 |
|---------|-----|------|------|
| id | bigint | PRIMARY KEY | ID |
| notification_type | string | | 通知タイプ |
| reference_type | string | | 参照タイプ |
| reference_id | bigint | | 参照ID |
| payload | text | | ペイロード |
| status | string | DEFAULT 'pending' | ステータス |
| webhook_url | string | | WebhookURL |

## インデックス戦略

### パフォーマンス最適化
1. **外部キー**: Rails 8.1が自動生成
2. **一意制約**: slug, nameフィールド
3. **複合インデックス**: 頻繁な検索条件
4. **GINインデックス**: JSONB検索用

### 主要なインデックス
- 記事の公開状態と日付での検索
- カテゴリ・タグのslug検索
- セクションのアクティブ状態検索
- JSONBコンテンツの全文検索

## データベース制約

### CHECK制約
```sql
-- ステータス値の制限
CHECK (status IN ('draft', 'published', 'scheduled', 'archived'))
CHECK (status IN ('unread', 'read', 'replied', 'archived'))

-- カラーコード形式
CHECK (color ~ '^#[0-9A-Fa-f]{6}$')
```

### 外部キー制約
- ON DELETE CASCADE: 親削除時に子も削除
- ON DELETE RESTRICT: 子がある場合は親を削除不可
- ON DELETE SET NULL: 親削除時にNULL設定

## データベース最適化

### PostgreSQL特有機能の活用
1. **JSONB型**: 柔軟なコンテンツ保存
2. **配列型**: tech_stack等の複数値
3. **INET型**: IPアドレス保存
4. **全文検索**: tsvector/tsquery

### パーティショニング（将来実装）
- access_logsテーブルの月次パーティション
- 古いデータの自動アーカイブ