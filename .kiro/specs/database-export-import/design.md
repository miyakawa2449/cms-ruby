# Design Document

## Overview

データベースエクスポート/インポート機能は、本番環境のデータを開発環境に移行するための管理画面機能です。管理者は管理画面のダッシュボードからボタン操作でデータをZIP形式でエクスポートし、別の環境でインポートできます。

この機能により、開発環境のデータが空になった際に、本番環境の実データを使って開発・テストを行うことが可能になります。

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Admin Dashboard                          │
│  ┌──────────────┐              ┌──────────────┐            │
│  │   Export     │              │   Import     │            │
│  │   Button     │              │   Button     │            │
│  └──────┬───────┘              └──────┬───────┘            │
└─────────┼──────────────────────────────┼──────────────────┘
          │                              │
          ▼                              ▼
┌─────────────────────┐        ┌─────────────────────┐
│  DatabaseExport     │        │  DatabaseImport     │
│  Service            │        │  Service            │
└─────────┬───────────┘        └─────────┬───────────┘
          │                              │
          ▼                              ▼
┌─────────────────────────────────────────────────────┐
│              Data Package (ZIP)                     │
│  ┌──────────────┐  ┌──────────────────────────┐   │
│  │  data.json   │  │  storage/                │   │
│  │              │  │    - blobs/              │   │
│  │  - models    │  │    - attachments/        │   │
│  │  - metadata  │  │                          │   │
│  └──────────────┘  └──────────────────────────┘   │
└─────────────────────────────────────────────────────┘
```

### Component Interaction Flow

**Export Flow:**
1. 管理者がダッシュボードの「Export」ボタンをクリック
2. `Admin::DatabaseController#export`が呼ばれる
3. `DatabaseExportService`がデータをJSON化
4. `ActiveStorageExportService`が添付ファイルをコピー
5. `ZipGeneratorService`がZIPファイルを生成
6. ブラウザにZIPファイルをダウンロード

**Import Flow:**
1. 管理者がダッシュボードの「Import」ボタンをクリック
2. ファイルアップロードフォームが表示される
3. ZIPファイルをアップロード
4. `Admin::DatabaseController#import`が呼ばれる
5. `ZipExtractorService`がZIPを解凍
6. `DatabaseImportService`がデータを投入
7. `ActiveStorageImportService`が添付ファイルを復元
8. 成功メッセージを表示


## Components and Interfaces

### 1. Admin::DatabaseController

管理画面からのエクスポート/インポートリクエストを処理するコントローラ。

```ruby
class Admin::DatabaseController < Admin::BaseController
  def export
    # エクスポート処理を実行し、ZIPファイルをダウンロード
  end

  def import_form
    # インポートフォームを表示
  end

  def import
    # アップロードされたZIPファイルをインポート
  end
end
```

**Responsibilities:**
- リクエストの受付とバリデーション
- サービスクラスの呼び出し
- レスポンスの生成（ファイルダウンロード、リダイレクト）
- エラーハンドリングとフラッシュメッセージ

### 2. DatabaseExportService

データベースレコードをJSON形式でエクスポートするサービス。

```ruby
class DatabaseExportService
  EXPORT_MODELS = [
    AdminUser,
    Article,
    Category,
    Tag,
    Section,
    SectionContent,
    MyStorySection,
    Contact,
    SiteSetting
  ].freeze

  def initialize
    @export_data = {}
  end

  def call
    export_all_models
    export_active_storage_metadata
    @export_data
  end

  private

  def export_all_models
    # 各モデルのレコードをJSON化
  end

  def export_active_storage_metadata
    # active_storage_blobs と active_storage_attachments をエクスポート
  end
end
```

**Responsibilities:**
- 全対象モデルのレコードをJSON化
- Active Storageのメタデータ（blobs、attachments）をエクスポート
- 関連付けを保持したデータ構造の生成


### 3. ActiveStorageExportService

Active Storageの添付ファイルを物理的にコピーするサービス。

```ruby
class ActiveStorageExportService
  def initialize(temp_dir)
    @temp_dir = temp_dir
    @storage_path = Rails.root.join("storage")
  end

  def call
    copy_storage_files
  end

  private

  def copy_storage_files
    # storage/ ディレクトリ全体を temp_dir/storage にコピー
  end
end
```

**Responsibilities:**
- `storage/` ディレクトリの全ファイルをコピー
- ディレクトリ構造を保持
- 進捗ログの出力

### 4. ZipGeneratorService

data.jsonとstorageフォルダをZIPファイルにまとめるサービス。

```ruby
class ZipGeneratorService
  def initialize(temp_dir, export_data)
    @temp_dir = temp_dir
    @export_data = export_data
  end

  def call
    write_data_json
    create_zip_file
  end

  private

  def write_data_json
    # data.json を temp_dir に書き込み
  end

  def create_zip_file
    # temp_dir の内容を ZIP 化
  end
end
```

**Responsibilities:**
- data.jsonファイルの生成
- ZIPファイルの作成
- 一時ファイルのクリーンアップ

### 5. DatabaseImportService

data.jsonからデータベースレコードを復元するサービス。

```ruby
class DatabaseImportService
  def initialize(data_json_path)
    @data = JSON.parse(File.read(data_json_path))
  end

  def call
    ActiveRecord::Base.transaction do
      clear_existing_data
      import_all_models
      import_active_storage_metadata
      reset_admin_passwords
      update_counter_caches
    end
  end

  private

  def clear_existing_data
    # 既存データを全削除
  end

  def import_all_models
    # 各モデルのレコードを投入
  end

  def import_active_storage_metadata
    # active_storage_blobs と active_storage_attachments を復元
  end

  def reset_admin_passwords
    # AdminUser のパスワードをリセット
  end

  def update_counter_caches
    # article_count などのカウンターキャッシュを更新
  end
end
```

**Responsibilities:**
- 既存データの削除
- レコードの投入（外部キー制約を考慮した順序）
- Active Storageメタデータの復元
- AdminUserパスワードのリセット
- カウンターキャッシュの更新
- トランザクション管理


### 6. ActiveStorageImportService

Active Storageの添付ファイルを物理的に復元するサービス。

```ruby
class ActiveStorageImportService
  def initialize(extracted_storage_path)
    @extracted_storage_path = extracted_storage_path
    @target_storage_path = Rails.root.join("storage")
  end

  def call
    restore_storage_files
  end

  private

  def restore_storage_files
    # extracted_storage_path から target_storage_path にファイルをコピー
  end
end
```

**Responsibilities:**
- 解凍されたstorageフォルダからファイルをコピー
- 既存のstorageフォルダをバックアップ（オプション）
- 進捗ログの出力

### 7. ZipExtractorService

アップロードされたZIPファイルを解凍するサービス。

```ruby
class ZipExtractorService
  def initialize(zip_file_path)
    @zip_file_path = zip_file_path
    @temp_dir = Dir.mktmpdir
  end

  def call
    extract_zip
    validate_contents
    @temp_dir
  end

  private

  def extract_zip
    # ZIP ファイルを temp_dir に解凍
  end

  def validate_contents
    # data.json の存在確認
    # storage/ ディレクトリの存在確認
  end
end
```

**Responsibilities:**
- ZIPファイルの解凍
- 必須ファイル（data.json）の存在確認
- 一時ディレクトリの管理

## Data Models

### Export Data Structure (data.json)

```json
{
  "metadata": {
    "exported_at": "2026-01-15T10:30:00Z",
    "rails_version": "8.1.1",
    "ruby_version": "3.3.0",
    "models_count": {
      "AdminUser": 2,
      "Article": 50,
      "Category": 10,
      "Tag": 30,
      "Section": 5,
      "SectionContent": 15,
      "MyStorySection": 8,
      "Contact": 20,
      "SiteSetting": 15
    }
  },
  "models": {
    "AdminUser": [
      {
        "id": 1,
        "email": "admin@example.com",
        "encrypted_password": "...",
        "created_at": "2025-01-01T00:00:00Z",
        ...
      }
    ],
    "Article": [...],
    "Category": [...],
    "Tag": [...],
    "Section": [...],
    "SectionContent": [...],
    "MyStorySection": [...],
    "Contact": [...],
    "SiteSetting": [...]
  },
  "active_storage": {
    "blobs": [
      {
        "id": 1,
        "key": "abc123...",
        "filename": "image.jpg",
        "content_type": "image/jpeg",
        "byte_size": 12345,
        ...
      }
    ],
    "attachments": [
      {
        "id": 1,
        "name": "thumbnail_image",
        "record_type": "Article",
        "record_id": 1,
        "blob_id": 1,
        ...
      }
    ]
  }
}
```

### Model Import Order

外部キー制約を考慮した投入順序：

1. **AdminUser** - 他のモデルから参照される
2. **Category** - 親子関係があるため、親から順に投入
3. **Tag** - 独立したモデル
4. **Section** - SectionContentから参照される
5. **Article** - AdminUserとCategoryを参照
6. **SectionContent** - SectionとAdminUserを参照
7. **MyStorySection** - 独立したモデル
8. **Contact** - AdminUserを参照（optional）
9. **SiteSetting** - 独立したモデル
10. **Active Storage (blobs → attachments)** - 最後に投入


## Correctness Properties

プロパティとは、システムの全ての有効な実行において真であるべき特性や動作のことです。プロパティは、人間が読める仕様と機械で検証可能な正しさの保証との橋渡しとなります。

### Property 1: Export includes all model records

*For any* データベース状態において、エクスポートされたdata.jsonは、AdminUser、Article、Category、Tag、Section、SectionContent、MyStorySection、Contact、SiteSettingの全レコードを含む

**Validates: Requirements 1.2**

### Property 2: Export includes all Active Storage files

*For any* Active Storage添付ファイルセットにおいて、エクスポートされたZIPファイルは、全ての添付ファイルとそのメタデータ（blobs、attachments）を含む

**Validates: Requirements 1.3**

### Property 3: Export generates valid ZIP structure

*For any* エクスポート実行において、生成されたZIPファイルは、data.jsonファイルとstorageフォルダを含む有効な構造を持つ

**Validates: Requirements 1.4**

### Property 4: Import-Export round trip preserves data

*For any* データベース状態において、エクスポートしてからインポートすると、元のデータベース状態と等価なデータが復元される（AdminUserのパスワードを除く）

**Validates: Requirements 2.2, 2.3, 6.1**

### Property 5: Import-Export round trip preserves Active Storage

*For any* Active Storage添付ファイルセットにおいて、エクスポートしてからインポートすると、全ての添付ファイルとメタデータが正しく復元される

**Validates: Requirements 2.4, 6.2**

### Property 6: Import resets all admin passwords

*For any* AdminUserレコードセットにおいて、インポート後は全てのAdminUserのパスワードが開発環境用のデフォルトパスワードにリセットされる

**Validates: Requirements 3.1**

### Property 7: Import transaction rollback on error

*For any* インポート処理において、データベースエラーが発生した場合、トランザクションがロールバックされ、データベースは元の状態を保つ

**Validates: Requirements 5.3**

### Property 8: Import validates all records

*For any* インポートされたデータにおいて、インポート完了後は全てのモデルレコードがそれぞれのバリデーションルールをパスする

**Validates: Requirements 6.4**

### Property 9: Import updates counter caches correctly

*For any* インポートされたデータにおいて、インポート完了後はarticle_count、tag_countなどの全てのカウンターキャッシュが正しい値に更新される

**Validates: Requirements 6.5**

### Property 10: Operations are logged

*For any* エクスポート/インポート操作において、操作の開始、完了、エラーが適切にRailsログに記録される

**Validates: Requirements 5.5, 7.3**

### Property 11: Export includes encrypted data

*For any* エクスポート実行において、エクスポートされたdata.jsonは、AdminUserのencrypted_passwordやContactの暗号化フィールドなどの機密情報を含む

**Validates: Requirements 7.5**


## Error Handling

### Error Scenarios

1. **無効なZIPファイル**
   - 破損したZIPファイル
   - ZIPでないファイル
   - 対応: `ZipExtractorService`でバリデーション、エラーメッセージ表示

2. **必須ファイルの欠落**
   - data.jsonが存在しない
   - storageフォルダが存在しない
   - 対応: `ZipExtractorService`で検証、エラーメッセージ表示

3. **データベースエラー**
   - 外部キー制約違反
   - バリデーションエラー
   - 対応: トランザクションロールバック、詳細なエラーログ

4. **ファイルシステムエラー**
   - ディスク容量不足
   - 権限エラー
   - 対応: エラーメッセージ表示、一時ファイルのクリーンアップ

5. **JSONパースエラー**
   - 不正なJSON形式
   - 対応: エラーメッセージ表示、処理中止

### Error Response Format

```ruby
{
  success: false,
  error: "エラーメッセージ",
  details: {
    type: "ValidationError",
    message: "詳細なエラー情報",
    backtrace: [...] # 開発環境のみ
  }
}
```

### Logging Strategy

- **INFO**: 処理開始、完了、進捗
- **WARN**: 警告（大量データ、本番環境でのインポートなど）
- **ERROR**: エラー詳細、スタックトレース

## Testing Strategy

### Unit Tests

各サービスクラスの個別機能をテスト：

- `DatabaseExportService`: モデルのJSON化、メタデータ生成
- `ActiveStorageExportService`: ファイルコピー
- `ZipGeneratorService`: ZIP生成、data.json書き込み
- `DatabaseImportService`: レコード投入、パスワードリセット、カウンター更新
- `ActiveStorageImportService`: ファイル復元
- `ZipExtractorService`: ZIP解凍、バリデーション

### Property-Based Tests

プロパティベーステストライブラリ: **RSpec + rspec-parameterized**

各プロパティを最低100回のランダムデータで検証：

- Property 1-11: 上記のCorrectnessPropertiesセクションで定義された各プロパティ
- テストタグ: `Feature: database-export-import, Property N: [property_text]`

### Integration Tests

コントローラとサービスの統合をテスト：

- エクスポートボタンからZIPダウンロードまでの流れ
- インポートフォームからデータ復元までの流れ
- エラーケースのハンドリング
- 認証・認可の検証

### Test Data Strategy

- FactoryBotでテストデータ生成
- 小規模データセット（各モデル5-10レコード）
- 中規模データセット（各モデル50-100レコード）
- Active Storage添付ファイルを含むデータセット

