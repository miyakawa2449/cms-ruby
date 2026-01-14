# メディアライブラリ管理機能 仕様書

## 📅 作成日・更新日
- **作成日**: 2024-12-26
- **最終更新**: 2024-12-26
- **ステータス**: 🔵 実装待ち（Phase5.1予定）

---

## 🎯 概要

### 目的
アップロードされた画像を一元管理できる管理画面を提供する。
画像の検索、フィルタリング、編集、削除、使用状況確認などの機能を実装し、
効率的なメディア管理を実現する。

### ユーザーストーリー
- 管理者として、アップロードした画像を一覧で確認したい、なぜなら画像を効率的に管理したいから
- 管理者として、画像を検索・フィルタリングしたい、なぜなら目的の画像を素早く見つけたいから
- 管理者として、画像の使用状況を確認したい、なぜなら不要な画像を安全に削除したいから
- 管理者として、画像を編集（トリミング・回転）したい、なぜなら記事に最適なサイズで使用したいから
- 管理者として、複数の画像を一括アップロードしたい、なぜなら作業効率を上げたいから

---

## ✅ 要件

### 機能要件

#### 1. 画像一覧表示
- [ ] グリッド表示（サムネイル形式）
- [ ] リスト表示（詳細情報付き）
- [ ] 表示切り替えボタン
- [ ] ページネーション（無限スクロール or ページ番号）
- [ ] 1ページあたりの表示件数変更（20/50/100件）

#### 2. 画像情報表示
- [ ] サムネイル画像
- [ ] ファイル名
- [ ] ファイルサイズ
- [ ] 画像サイズ（幅x高さ）
- [ ] アップロード日時
- [ ] 使用状況（使用中の記事数）
- [ ] alt属性
- [ ] URL（コピーボタン付き）

#### 3. 検索・フィルタリング
- [ ] ファイル名検索
- [ ] 日付範囲フィルタ
- [ ] ファイルサイズフィルタ
- [ ] 使用状況フィルタ（使用中/未使用）
- [ ] ファイル形式フィルタ（JPEG/PNG/GIF/WebP）
- [ ] 並び替え（日付/サイズ/ファイル名）

#### 4. 画像アップロード
- [ ] ドラッグ&ドロップアップロード
- [ ] ファイル選択ダイアログ
- [ ] 複数ファイル同時アップロード
- [ ] アップロード進捗表示（プログレスバー）
- [ ] アップロード完了通知
- [ ] エラーハンドリング（ファイル形式・サイズ制限）

#### 5. 画像編集機能
- [ ] トリミング（クロップ）
- [ ] アスペクト比固定オプション（16:9, 4:3, 1:1, 自由）
- [ ] 回転（90度単位）
- [ ] 反転（水平・垂直）
- [ ] プレビュー表示
- [ ] 編集内容の保存（新規ファイルとして保存 or 上書き）

#### 6. 画像最適化
- [ ] WebP自動変換オプション
- [ ] 複数サイズ生成（サムネイル・中・大）
- [ ] 画像圧縮（品質設定）
- [ ] 遅延読み込み用データ生成

#### 7. 画像操作
- [ ] 画像詳細モーダル表示
- [ ] alt属性編集
- [ ] 画像削除（確認ダイアログ付き）
- [ ] 一括削除
- [ ] 使用状況確認（どの記事で使用されているか）
- [ ] URLコピー機能

#### 8. 使用状況管理
- [ ] 画像が使用されている記事一覧表示
- [ ] 記事へのリンク
- [ ] 未使用画像の一括検出
- [ ] 削除前の使用状況警告

### 非機能要件
- **パフォーマンス**: 
  - 画像一覧読み込み < 1秒
  - サムネイル生成の非同期処理
  - 大量画像（1000枚以上）でも快適に動作
- **ユーザビリティ**: 
  - 直感的なUI/UX
  - ドラッグ&ドロップ対応
  - キーボードショートカット対応
- **セキュリティ**: 
  - アップロード可能なファイル形式制限
  - ファイルサイズ制限（10MB）
  - 管理者権限チェック
- **アクセシビリティ**: 
  - キーボード操作対応
  - スクリーンリーダー対応

---

## 🖼️ 画面仕様

### UI/UX詳細

#### メディアライブラリ一覧画面（グリッド表示）

```
┌─────────────────────────────────────────────────────────────┐
│ メディアライブラリ                                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ [📤 アップロード] [🗑️ 一括削除]    [グリッド] [リスト]    │
│                                                             │
│ 🔍 [ファイル名検索...]                                      │
│                                                             │
│ フィルタ: [すべて ▼] [日付 ▼] [サイズ ▼] [使用状況 ▼]    │
│                                                             │
│ 並び替え: [新しい順 ▼]  表示件数: [50件 ▼]                │
│                                                             │
│ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐         │
│ │  [画像]  │ │  [画像]  │ │  [画像]  │ │  [画像]  │         │
│ │         │ │         │ │         │ │         │         │
│ │ image1  │ │ image2  │ │ image3  │ │ image4  │         │
│ │ 2.3MB   │ │ 1.8MB   │ │ 3.1MB   │ │ 1.2MB   │         │
│ │ 使用中  │ │ 未使用  │ │ 使用中  │ │ 使用中  │         │
│ │ [✏️][🗑️] │ │ [✏️][🗑️] │ │ [✏️][🗑️] │ │ [✏️][🗑️] │         │
│ └─────────┘ └─────────┘ └─────────┘ └─────────┘         │
│                                                             │
│ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐         │
│ │  [画像]  │ │  [画像]  │ │  [画像]  │ │  [画像]  │         │
│ └─────────┘ └─────────┘ └─────────┘ └─────────┘         │
│                                                             │
│ [1] 2 3 4 ... 10 次へ >                                    │
└─────────────────────────────────────────────────────────────┘
```

#### メディアライブラリ一覧画面（リスト表示）

```
┌─────────────────────────────────────────────────────────────┐
│ メディアライブラリ                                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ [📤 アップロード] [🗑️ 一括削除]    [グリッド] [リスト]    │
│                                                             │
│ ┌───────────────────────────────────────────────────────┐ │
│ │ [画像] image1.jpg                                     │ │
│ │        1920x1080 | 2.3MB | 2024-12-26 10:30          │ │
│ │        使用中: 3記事 | [詳細] [編集] [削除]          │ │
│ ├───────────────────────────────────────────────────────┤ │
│ │ [画像] image2.png                                     │ │
│ │        1280x720 | 1.8MB | 2024-12-25 15:20           │ │
│ │        未使用 | [詳細] [編集] [削除]                  │ │
│ ├───────────────────────────────────────────────────────┤ │
│ │ [画像] image3.jpg                                     │ │
│ │        2560x1440 | 3.1MB | 2024-12-24 09:15          │ │
│ │        使用中: 1記事 | [詳細] [編集] [削除]          │ │
│ └───────────────────────────────────────────────────────┘ │
│                                                             │
│ [1] 2 3 4 ... 10 次へ >                                    │
└─────────────────────────────────────────────────────────────┘
```

#### 画像詳細モーダル

```
┌─────────────────────────────────────────────────────────────┐
│ 画像詳細                                          [✕ 閉じる] │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ ┌─────────────────────────┐  ファイル情報                  │
│ │                         │  ━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│ │                         │  ファイル名: image1.jpg        │
│ │      [プレビュー]        │  サイズ: 1920x1080            │
│ │                         │  容量: 2.3MB                   │
│ │                         │  形式: JPEG                    │
│ │                         │  アップロード: 2024-12-26      │
│ └─────────────────────────┘                                │
│                                                             │
│ alt属性                                                     │
│ [画像の説明を入力してください                            ] │
│                                                             │
│ URL                                                         │
│ [https://example.com/image1.jpg        ] [📋 コピー]       │
│                                                             │
│ 使用状況                                                    │
│ ┌─────────────────────────────────────────────────────┐   │
│ │ ✓ 記事: Railsで始めるWeb開発 (2024-12-20)          │   │
│ │ ✓ 記事: Dockerの基礎 (2024-12-18)                  │   │
│ │ ✓ 記事: PostgreSQL入門 (2024-12-15)                │   │
│ └─────────────────────────────────────────────────────┘   │
│                                                             │
│ [編集] [削除] [閉じる]                                      │
└─────────────────────────────────────────────────────────────┘
```

#### 画像編集モーダル

```
┌─────────────────────────────────────────────────────────────┐
│ 画像編集                                          [✕ 閉じる] │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ ツール: [✂️ トリミング] [🔄 回転] [↔️ 反転]                │
│                                                             │
│ アスペクト比: [自由 ▼] [16:9] [4:3] [1:1]                 │
│                                                             │
│ ┌─────────────────────────────────────────────────────┐   │
│ │                                                     │   │
│ │                                                     │   │
│ │              [編集プレビュー]                        │   │
│ │                                                     │   │
│ │                                                     │   │
│ └─────────────────────────────────────────────────────┘   │
│                                                             │
│ 回転: [⟲ 左90°] [⟳ 右90°]                                 │
│ 反転: [↔️ 水平] [↕️ 垂直]                                  │
│                                                             │
│ 保存オプション:                                             │
│ ○ 新規ファイルとして保存                                   │
│ ○ 上書き保存                                               │
│                                                             │
│ [キャンセル] [保存]                                         │
└─────────────────────────────────────────────────────────────┘
```

#### アップロードモーダル

```
┌─────────────────────────────────────────────────────────────┐
│ 画像アップロード                                  [✕ 閉じる] │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ ┌─────────────────────────────────────────────────────┐   │
│ │                                                     │   │
│ │         📤 ここにファイルをドロップ                  │   │
│ │              または                                 │   │
│ │         [ファイルを選択]                            │   │
│ │                                                     │   │
│ │   対応形式: JPEG, PNG, GIF, WebP                    │   │
│ │   最大サイズ: 10MB                                  │   │
│ └─────────────────────────────────────────────────────┘   │
│                                                             │
│ アップロード中:                                             │
│ ┌─────────────────────────────────────────────────────┐   │
│ │ image1.jpg ████████████████░░░░ 80% (2.3MB)        │   │
│ │ image2.png ████████████████████ 100% (1.8MB) ✓     │   │
│ │ image3.jpg ██████░░░░░░░░░░░░░░ 30% (3.1MB)        │   │
│ └─────────────────────────────────────────────────────┘   │
│                                                             │
│ オプション:                                                 │
│ ☑ WebP形式に自動変換                                       │
│ ☑ サムネイル自動生成                                       │
│                                                             │
│ [キャンセル] [完了]                                         │
└─────────────────────────────────────────────────────────────┘
```

---

## 🗄️ データ仕様

### 使用するモデル

#### ActiveStorage::Attachment（既存）
Active Storageの標準モデルを使用

#### MediaMetadata（新規作成）
画像のメタデータを管理する補助テーブル

```ruby
create_table :media_metadata do |t|
  t.references :attachment, foreign_key: { to_table: :active_storage_attachments }
  t.string :alt_text
  t.integer :width
  t.integer :height
  t.string :mime_type
  t.integer :file_size
  t.jsonb :variants, default: {}  # サムネイル、中、大サイズのURL
  t.integer :usage_count, default: 0
  t.timestamps
end

add_index :media_metadata, :attachment_id, unique: true
add_index :media_metadata, :usage_count
add_index :media_metadata, :created_at
```

### データフロー

```
1. 画像アップロード
   ↓
2. Active Storageに保存
   ↓
3. MediaMetadataレコード作成
   ↓
4. 画像解析（サイズ、形式取得）
   ↓
5. サムネイル生成（非同期）
   ↓
6. WebP変換（オプション・非同期）
   ↓
7. メタデータ更新

使用状況追跡:
1. 記事に画像挿入
   ↓
2. usage_countインクリメント
   ↓
3. 記事から画像削除
   ↓
4. usage_countデクリメント
```

### 画像バリアント定義

```ruby
# app/models/concerns/image_variants.rb
module ImageVariants
  VARIANTS = {
    thumb: { resize_to_limit: [150, 150] },
    medium: { resize_to_limit: [800, 600] },
    large: { resize_to_limit: [1920, 1080] }
  }
  
  def generate_variants
    VARIANTS.each do |name, transformations|
      variant = self.variant(transformations)
      # バリアントURLを保存
    end
  end
end
```

---

## 🔌 API仕様

### エンドポイント

```
GET    /admin/media                    # 画像一覧
POST   /admin/media                    # 画像アップロード
GET    /admin/media/:id                # 画像詳細
PATCH  /admin/media/:id                # 画像情報更新
DELETE /admin/media/:id                # 画像削除
POST   /admin/media/:id/edit           # 画像編集（トリミング等）
GET    /admin/media/:id/usage          # 使用状況取得
DELETE /admin/media/bulk_destroy       # 一括削除
```

### リクエスト・レスポンス例

#### 画像一覧取得

**リクエスト**:
```
GET /admin/media?page=1&per_page=50&view=grid&sort=created_at_desc&filter[usage]=all
```

**レスポンス**:
```json
{
  "success": true,
  "data": {
    "media": [
      {
        "id": 1,
        "filename": "image1.jpg",
        "url": "https://example.com/image1.jpg",
        "thumbnail_url": "https://example.com/image1_thumb.jpg",
        "alt_text": "画像の説明",
        "width": 1920,
        "height": 1080,
        "file_size": 2457600,
        "mime_type": "image/jpeg",
        "usage_count": 3,
        "created_at": "2024-12-26T10:30:00Z",
        "variants": {
          "thumb": "https://example.com/image1_thumb.jpg",
          "medium": "https://example.com/image1_medium.jpg",
          "large": "https://example.com/image1_large.jpg"
        }
      }
    ],
    "meta": {
      "current_page": 1,
      "total_pages": 10,
      "total_count": 487,
      "per_page": 50
    }
  }
}
```

#### 画像アップロード

**リクエスト**:
```
POST /admin/media
Content-Type: multipart/form-data

{
  images: [File, File, ...],
  generate_webp: true,
  generate_thumbnails: true
}
```

**レスポンス**:
```json
{
  "success": true,
  "data": {
    "uploaded": [
      {
        "id": 1,
        "filename": "image1.jpg",
        "url": "https://example.com/image1.jpg",
        "status": "success"
      }
    ],
    "failed": [
      {
        "filename": "invalid.txt",
        "error": "Invalid file type"
      }
    ]
  }
}
```

#### 画像編集

**リクエスト**:
```
POST /admin/media/:id/edit

{
  "operation": "crop",
  "params": {
    "x": 100,
    "y": 100,
    "width": 800,
    "height": 600
  },
  "save_as_new": true
}
```

**レスポンス**:
```json
{
  "success": true,
  "data": {
    "id": 2,
    "filename": "image1_cropped.jpg",
    "url": "https://example.com/image1_cropped.jpg"
  }
}
```

#### 使用状況取得

**リクエスト**:
```
GET /admin/media/:id/usage
```

**レスポンス**:
```json
{
  "success": true,
  "data": {
    "usage_count": 3,
    "articles": [
      {
        "id": 1,
        "title": "Railsで始めるWeb開発",
        "published_at": "2024-12-20T10:00:00Z",
        "url": "/blog/rails-web-development"
      },
      {
        "id": 2,
        "title": "Dockerの基礎",
        "published_at": "2024-12-18T15:00:00Z",
        "url": "/blog/docker-basics"
      }
    ]
  }
}
```

---

## 🧪 受け入れ基準

実装完了の判断基準：

### 画像一覧・表示
- [ ] グリッド表示とリスト表示が切り替えられる
- [ ] サムネイル画像が正しく表示される
- [ ] ファイル情報（名前、サイズ、日付）が表示される
- [ ] 使用状況が正しく表示される
- [ ] ページネーションが正常に動作する
- [ ] 表示件数変更が正常に動作する

### 検索・フィルタリング
- [ ] ファイル名検索が正常に動作する
- [ ] 日付範囲フィルタが正常に動作する
- [ ] ファイルサイズフィルタが正常に動作する
- [ ] 使用状況フィルタが正常に動作する
- [ ] 並び替えが正常に動作する
- [ ] 複数条件の組み合わせが正常に動作する

### 画像アップロード
- [ ] ドラッグ&ドロップでアップロードできる
- [ ] ファイル選択ダイアログでアップロードできる
- [ ] 複数ファイルを同時にアップロードできる
- [ ] アップロード進捗が表示される
- [ ] アップロード完了通知が表示される
- [ ] 不正なファイル形式が拒否される
- [ ] ファイルサイズ制限が機能する

### 画像編集
- [ ] トリミング機能が正常に動作する
- [ ] アスペクト比固定が正常に動作する
- [ ] 回転機能が正常に動作する
- [ ] 反転機能が正常に動作する
- [ ] プレビューが正しく表示される
- [ ] 新規ファイルとして保存できる
- [ ] 上書き保存できる

### 画像最適化
- [ ] WebP自動変換が正常に動作する
- [ ] サムネイル生成が正常に動作する
- [ ] 複数サイズ生成が正常に動作する
- [ ] 画像圧縮が正常に動作する

### 画像操作
- [ ] 画像詳細モーダルが表示される
- [ ] alt属性を編集できる
- [ ] URLをコピーできる
- [ ] 画像を削除できる（確認ダイアログ付き）
- [ ] 一括削除ができる
- [ ] 使用中の画像削除時に警告が表示される

### 使用状況管理
- [ ] 使用中の記事一覧が表示される
- [ ] 記事へのリンクが正常に動作する
- [ ] 未使用画像が正しく検出される
- [ ] 使用状況カウントが正確

### パフォーマンス
- [ ] 画像一覧読み込みが1秒以内
- [ ] サムネイル生成が非同期で処理される
- [ ] 1000枚以上の画像でも快適に動作する
- [ ] N+1クエリが発生していない

### UI/UX
- [ ] レスポンシブデザインが適切に動作する
- [ ] モバイル表示が適切
- [ ] ローディング表示が適切
- [ ] エラーメッセージが分かりやすい

---

## 🧪 テスト仕様

### TDD適用判断

- [x] TDD適用: はい
- **理由**: ファイル操作、使用状況追跡、画像処理など複雑なロジックが多いため

### テスト対象

| 対象 | ファイルパス | テストファイルパス |
|------|-------------|-------------------|
| Model | `app/models/media_metadata.rb` | `spec/models/media_metadata_spec.rb` |
| Service | `app/services/media/upload_service.rb` | `spec/services/media/upload_service_spec.rb` |
| Service | `app/services/media/edit_service.rb` | `spec/services/media/edit_service_spec.rb` |
| Service | `app/services/media/usage_tracker_service.rb` | `spec/services/media/usage_tracker_service_spec.rb` |
| Controller | `app/controllers/admin/media_controller.rb` | `spec/controllers/admin/media_controller_spec.rb` |
| Job | `app/jobs/media/generate_variants_job.rb` | `spec/jobs/media/generate_variants_job_spec.rb` |

### Model: MediaMetadata

#### describe '#track_usage'

**正常系**:
- [ ] 使用状況カウントをインクリメントする
- [ ] 複数回呼び出すと正しくカウントされる

#### describe '#untrack_usage'

**正常系**:
- [ ] 使用状況カウントをデクリメントする
- [ ] カウントが0以下にならない

#### describe '#generate_variants'

**正常系**:
- [ ] サムネイル、中、大サイズのバリアントを生成する
- [ ] バリアントURLをvariantsに保存する

**異常系**:
- [ ] 画像でない場合、何もしない

### Service: Media::UploadService

#### describe '#call'

**正常系**:
- [ ] 画像ファイルをアップロードする
- [ ] MediaMetadataレコードを作成する
- [ ] 画像サイズを取得して保存する
- [ ] 複数ファイルを同時にアップロードできる
- [ ] アップロード成功リストを返す

**異常系**:
- [ ] 不正なファイル形式を拒否する
- [ ] ファイルサイズ超過を拒否する
- [ ] 失敗したファイルのリストを返す

### Service: Media::EditService

#### describe '#crop_image'

**正常系**:
- [ ] 画像をトリミングする
- [ ] 新規ファイルとして保存できる
- [ ] 上書き保存できる

#### describe '#rotate_image'

**正常系**:
- [ ] 画像を回転する（90度単位）
- [ ] 回転後の画像を保存する

### Service: Media::UsageTrackerService

#### describe '#track'

**正常系**:
- [ ] 記事に画像が追加されたときusage_countをインクリメントする
- [ ] 記事から画像が削除されたときusage_countをデクリメントする
- [ ] 複数の記事で使用されている場合、正しくカウントする

### テストコード例

```ruby
# spec/models/media_metadata_spec.rb
require 'rails_helper'

RSpec.describe MediaMetadata, type: :model do
  let(:attachment) { create(:active_storage_attachment) }
  let(:metadata) { create(:media_metadata, attachment: attachment) }
  
  describe 'associations' do
    it { should belong_to(:attachment) }
  end
  
  describe 'validations' do
    it { should validate_presence_of(:attachment) }
  end
  
  describe '#track_usage' do
    it '使用状況カウントをインクリメントする' do
      article = create(:article)
      
      expect {
        metadata.track_usage(article)
      }.to change { metadata.reload.usage_count }.by(1)
    end
    
    it '複数回呼び出すと正しくカウントされる' do
      article1 = create(:article)
      article2 = create(:article)
      
      metadata.track_usage(article1)
      metadata.track_usage(article2)
      
      expect(metadata.reload.usage_count).to eq(2)
    end
  end
  
  describe '#untrack_usage' do
    before do
      metadata.update(usage_count: 2)
    end
    
    it '使用状況カウントをデクリメントする' do
      article = create(:article)
      
      expect {
        metadata.untrack_usage(article)
      }.to change { metadata.reload.usage_count }.by(-1)
    end
    
    it 'カウントが0以下にならない' do
      metadata.update(usage_count: 0)
      article = create(:article)
      
      metadata.untrack_usage(article)
      
      expect(metadata.reload.usage_count).to eq(0)
    end
  end
  
  describe '#generate_variants' do
    it 'サムネイル、中、大サイズのバリアントを生成する' do
      # Active Storageのモック設定
      allow(attachment).to receive(:image?).and_return(true)
      allow(attachment).to receive(:variant).and_return(double(processed: double(url: 'http://example.com/variant.jpg')))
      
      metadata.generate_variants
      
      expect(metadata.variants).to have_key('thumb')
      expect(metadata.variants).to have_key('medium')
      expect(metadata.variants).to have_key('large')
    end
    
    it '画像でない場合、何もしない' do
      allow(attachment).to receive(:image?).and_return(false)
      
      metadata.generate_variants
      
      expect(metadata.variants).to be_empty
    end
  end
end
```

```ruby
# spec/services/media/upload_service_spec.rb
require 'rails_helper'

RSpec.describe Media::UploadService do
  let(:image_file) { fixture_file_upload('spec/fixtures/files/test_image.jpg', 'image/jpeg') }
  let(:large_file) { fixture_file_upload('spec/fixtures/files/large_image.jpg', 'image/jpeg') }
  let(:invalid_file) { fixture_file_upload('spec/fixtures/files/test.txt', 'text/plain') }
  
  describe '#call' do
    context '正常系' do
      it '画像ファイルをアップロードする' do
        service = described_class.new([image_file])
        
        result = service.call
        
        expect(result[:uploaded].count).to eq(1)
        expect(result[:uploaded].first[:status]).to eq('success')
      end
      
      it 'MediaMetadataレコードを作成する' do
        service = described_class.new([image_file])
        
        expect {
          service.call
        }.to change(MediaMetadata, :count).by(1)
      end
      
      it '画像サイズを取得して保存する' do
        service = described_class.new([image_file])
        
        service.call
        
        metadata = MediaMetadata.last
        expect(metadata.width).to be > 0
        expect(metadata.height).to be > 0
      end
      
      it '複数ファイルを同時にアップロードできる' do
        image_file2 = fixture_file_upload('spec/fixtures/files/test_image2.jpg', 'image/jpeg')
        service = described_class.new([image_file, image_file2])
        
        result = service.call
        
        expect(result[:uploaded].count).to eq(2)
      end
    end
    
    context '異常系' do
      it '不正なファイル形式を拒否する' do
        service = described_class.new([invalid_file])
        
        result = service.call
        
        expect(result[:failed].count).to eq(1)
        expect(result[:failed].first[:error]).to include('Invalid file type')
      end
      
      it 'ファイルサイズ超過を拒否する' do
        # 10MB超のファイルをモック
        allow(large_file).to receive(:size).and_return(11.megabytes)
        service = described_class.new([large_file])
        
        result = service.call
        
        expect(result[:failed].count).to eq(1)
        expect(result[:failed].first[:error]).to include('File size exceeds limit')
      end
    end
  end
end
```

```ruby
# spec/services/media/edit_service_spec.rb
require 'rails_helper'

RSpec.describe Media::EditService do
  let(:attachment) { create(:active_storage_attachment) }
  let(:metadata) { create(:media_metadata, attachment: attachment) }
  
  describe '#crop_image' do
    let(:params) { { x: 100, y: 100, width: 800, height: 600, save_as_new: true } }
    
    it '画像をトリミングする' do
      service = described_class.new(metadata, 'crop', params)
      
      # Active Storageのモック
      variant = double(processed: double(url: 'http://example.com/cropped.jpg'))
      allow(attachment).to receive(:variant).and_return(variant)
      
      result = service.call
      
      expect(result[:success]).to be true
    end
    
    it '新規ファイルとして保存できる' do
      service = described_class.new(metadata, 'crop', params.merge(save_as_new: true))
      
      expect {
        service.call
      }.to change(MediaMetadata, :count).by(1)
    end
    
    it '上書き保存できる' do
      service = described_class.new(metadata, 'crop', params.merge(save_as_new: false))
      
      expect {
        service.call
      }.not_to change(MediaMetadata, :count)
    end
  end
  
  describe '#rotate_image' do
    let(:params) { { degrees: 90 } }
    
    it '画像を回転する' do
      service = described_class.new(metadata, 'rotate', params)
      
      variant = double(processed: double(url: 'http://example.com/rotated.jpg'))
      allow(attachment).to receive(:variant).and_return(variant)
      
      result = service.call
      
      expect(result[:success]).to be true
    end
  end
end
```

```ruby
# spec/services/media/usage_tracker_service_spec.rb
require 'rails_helper'

RSpec.describe Media::UsageTrackerService do
  let(:tracker) { described_class.new }
  let(:article) { create(:article) }
  let(:attachment) { create(:active_storage_attachment) }
  let(:metadata) { create(:media_metadata, attachment: attachment, usage_count: 0) }
  
  describe '#track' do
    it '記事に画像が追加されたときusage_countをインクリメントする' do
      expect {
        tracker.track(article, attachment)
      }.to change { metadata.reload.usage_count }.by(1)
    end
    
    it '複数の記事で使用されている場合、正しくカウントする' do
      article2 = create(:article)
      
      tracker.track(article, attachment)
      tracker.track(article2, attachment)
      
      expect(metadata.reload.usage_count).to eq(2)
    end
  end
  
  describe '#untrack' do
    before do
      metadata.update(usage_count: 2)
    end
    
    it '記事から画像が削除されたときusage_countをデクリメントする' do
      expect {
        tracker.untrack(article, attachment)
      }.to change { metadata.reload.usage_count }.by(-1)
    end
  end
end
```

```ruby
# spec/controllers/admin/media_controller_spec.rb
require 'rails_helper'

RSpec.describe Admin::MediaController, type: :controller do
  let(:admin_user) { create(:admin_user) }
  
  before do
    sign_in admin_user
  end
  
  describe 'GET #index' do
    it '画像一覧を表示する' do
      create_list(:media_metadata, 3)
      
      get :index
      
      expect(response).to have_http_status(:success)
      expect(assigns(:media).count).to eq(3)
    end
    
    it 'ファイル名検索が機能する' do
      metadata1 = create(:media_metadata, filename: 'test_image.jpg')
      metadata2 = create(:media_metadata, filename: 'other_image.jpg')
      
      get :index, params: { q: 'test' }
      
      expect(assigns(:media)).to include(metadata1)
      expect(assigns(:media)).not_to include(metadata2)
    end
    
    it '使用状況フィルタが機能する' do
      used = create(:media_metadata, usage_count: 3)
      unused = create(:media_metadata, usage_count: 0)
      
      get :index, params: { filter: { usage: 'used' } }
      
      expect(assigns(:media)).to include(used)
      expect(assigns(:media)).not_to include(unused)
    end
  end
  
  describe 'POST #create' do
    let(:image_file) { fixture_file_upload('spec/fixtures/files/test_image.jpg', 'image/jpeg') }
    
    it '画像をアップロードする' do
      expect {
        post :create, params: { images: [image_file] }
      }.to change(MediaMetadata, :count).by(1)
      
      expect(response).to have_http_status(:success)
    end
  end
  
  describe 'DELETE #destroy' do
    let(:metadata) { create(:media_metadata, usage_count: 0) }
    
    it '未使用画像を削除できる' do
      expect {
        delete :destroy, params: { id: metadata.id }
      }.to change(MediaMetadata, :count).by(-1)
    end
    
    it '使用中の画像削除時に警告を表示する' do
      metadata.update(usage_count: 3)
      
      delete :destroy, params: { id: metadata.id }
      
      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['error']).to include('使用中')
    end
  end
end
```

```ruby
# spec/jobs/media/generate_variants_job_spec.rb
require 'rails_helper'

RSpec.describe Media::GenerateVariantsJob, type: :job do
  let(:metadata) { create(:media_metadata) }
  
  it 'バリアントを生成する' do
    expect(metadata).to receive(:generate_variants)
    
    described_class.perform_now(metadata.id)
  end
  
  it '非同期で実行される' do
    expect {
      described_class.perform_later(metadata.id)
    }.to have_enqueued_job(described_class)
  end
end
```

### テストデータ（FactoryBot）

```ruby
# spec/factories/media_metadata.rb
FactoryBot.define do
  factory :media_metadata do
    association :attachment, factory: :active_storage_attachment
    alt_text { 'テスト画像' }
    width { 1920 }
    height { 1080 }
    mime_type { 'image/jpeg' }
    file_size { 2457600 }
    variants { {} }
    usage_count { 0 }
    
    trait :used do
      usage_count { 3 }
    end
    
    trait :with_variants do
      variants do
        {
          'thumb' => 'http://example.com/thumb.jpg',
          'medium' => 'http://example.com/medium.jpg',
          'large' => 'http://example.com/large.jpg'
        }
      end
    end
  end
end

# spec/factories/active_storage_attachments.rb
FactoryBot.define do
  factory :active_storage_attachment, class: 'ActiveStorage::Attachment' do
    name { 'content_images' }
    record_type { 'Article' }
    association :record, factory: :article
    association :blob, factory: :active_storage_blob
  end
end

# spec/factories/active_storage_blobs.rb
FactoryBot.define do
  factory :active_storage_blob, class: 'ActiveStorage::Blob' do
    key { SecureRandom.uuid }
    filename { 'test_image.jpg' }
    content_type { 'image/jpeg' }
    metadata { { width: 1920, height: 1080 } }
    byte_size { 2457600 }
    checksum { 'test_checksum' }
  end
end
```

### テストフィクスチャ

```
# spec/fixtures/files/
test_image.jpg      # 100x100px, 10KB
test_image2.jpg     # 200x200px, 20KB
large_image.jpg     # 2000x2000px, 5MB
test.txt            # テキストファイル（不正なファイル形式テスト用）
```

### パフォーマンステスト

```ruby
# spec/models/media_metadata_spec.rb (追加)
describe 'パフォーマンス' do
  it '1000件の画像でも1秒以内に一覧取得できる' do
    create_list(:media_metadata, 1000)
    
    start_time = Time.current
    MediaMetadata.all.to_a
    end_time = Time.current
    
    expect(end_time - start_time).to be < 1.0
  end
  
  it 'N+1クエリが発生しない' do
    create_list(:media_metadata, 10, :with_variants)
    
    expect {
      MediaMetadata.includes(:attachment).each do |metadata|
        metadata.attachment.filename
        metadata.variants
      end
    }.to perform_queries(count: 2..3)
  end
end
```

### カバレッジ目標

- Model: 95%以上
- Service: 95%以上
- Controller: 90%以上
- Job: 90%以上

---

## 💡 実装メモ

### 実装対象ファイル

#### バックエンド

1. **コントローラー**: `app/controllers/admin/media_controller.rb`
   - CRUD操作
   - 検索・フィルタリング
   - 一括操作

2. **モデル**: `app/models/media_metadata.rb`
   - メタデータ管理
   - 使用状況追跡
   - バリアント管理

3. **サービス**: `app/services/media/`
   - `upload_service.rb` - アップロード処理
   - `edit_service.rb` - 画像編集処理
   - `optimization_service.rb` - 画像最適化
   - `usage_tracker_service.rb` - 使用状況追跡

4. **ジョブ**: `app/jobs/media/`
   - `generate_variants_job.rb` - バリアント生成
   - `convert_to_webp_job.rb` - WebP変換
   - `optimize_image_job.rb` - 画像最適化

#### フロントエンド

1. **ビュー**: `app/views/admin/media/`
   - `index.html.erb` - 一覧画面
   - `_grid.html.erb` - グリッド表示パーシャル
   - `_list.html.erb` - リスト表示パーシャル
   - `_detail_modal.html.erb` - 詳細モーダル
   - `_edit_modal.html.erb` - 編集モーダル
   - `_upload_modal.html.erb` - アップロードモーダル

2. **JavaScript**: `app/javascript/controllers/media/`
   - `library_controller.js` - 一覧管理
   - `upload_controller.js` - アップロード処理
   - `edit_controller.js` - 画像編集
   - `filter_controller.js` - フィルタリング

3. **CSS**: `app/assets/stylesheets/admin/media.css`
   - メディアライブラリ専用スタイル

### 実装アプローチ

#### 1. Active Storage統合

```ruby
# app/models/media_metadata.rb
class MediaMetadata < ApplicationRecord
  belongs_to :attachment, class_name: 'ActiveStorage::Attachment'
  
  # 使用状況追跡
  def track_usage(article)
    increment!(:usage_count)
  end
  
  def untrack_usage(article)
    decrement!(:usage_count)
  end
  
  # バリアント生成
  def generate_variants
    return unless attachment.image?
    
    ImageVariants::VARIANTS.each do |name, transformations|
      variant_url = attachment.variant(transformations).processed.url
      variants[name] = variant_url
    end
    
    save!
  end
end
```

#### 2. 画像アップロード処理

```ruby
# app/services/media/upload_service.rb
class Media::UploadService
  def initialize(files, options = {})
    @files = files
    @generate_webp = options[:generate_webp]
    @generate_thumbnails = options[:generate_thumbnails]
  end
  
  def call
    results = { uploaded: [], failed: [] }
    
    @files.each do |file|
      if valid_file?(file)
        attachment = create_attachment(file)
        metadata = create_metadata(attachment)
        
        # 非同期処理
        Media::GenerateVariantsJob.perform_later(metadata.id) if @generate_thumbnails
        Media::ConvertToWebpJob.perform_later(metadata.id) if @generate_webp
        
        results[:uploaded] << format_success(attachment, metadata)
      else
        results[:failed] << format_error(file)
      end
    end
    
    results
  end
  
  private
  
  def valid_file?(file)
    valid_mime_type?(file) && valid_file_size?(file)
  end
  
  def valid_mime_type?(file)
    %w[image/jpeg image/png image/gif image/webp].include?(file.content_type)
  end
  
  def valid_file_size?(file)
    file.size <= 10.megabytes
  end
end
```

#### 3. 画像編集処理

```ruby
# app/services/media/edit_service.rb
class Media::EditService
  def initialize(media_metadata, operation, params)
    @metadata = media_metadata
    @operation = operation
    @params = params
  end
  
  def call
    case @operation
    when 'crop'
      crop_image
    when 'rotate'
      rotate_image
    when 'flip'
      flip_image
    end
  end
  
  private
  
  def crop_image
    attachment = @metadata.attachment
    
    cropped = attachment.variant(
      crop: "#{@params[:width]}x#{@params[:height]}+#{@params[:x]}+#{@params[:y]}"
    ).processed
    
    if @params[:save_as_new]
      create_new_attachment(cropped)
    else
      update_attachment(cropped)
    end
  end
  
  def rotate_image
    attachment = @metadata.attachment
    
    rotated = attachment.variant(
      rotate: @params[:degrees]
    ).processed
    
    # 保存処理
  end
end
```

#### 4. 使用状況追跡

```ruby
# app/models/article.rb
class Article < ApplicationRecord
  has_many_attached :content_images
  
  after_save :track_image_usage
  before_destroy :untrack_image_usage
  
  private
  
  def track_image_usage
    # 本文から画像URLを抽出
    image_urls = extract_image_urls_from_content
    
    image_urls.each do |url|
      attachment = find_attachment_by_url(url)
      next unless attachment
      
      metadata = MediaMetadata.find_by(attachment: attachment)
      metadata&.track_usage(self)
    end
  end
  
  def untrack_image_usage
    content_images.each do |image|
      metadata = MediaMetadata.find_by(attachment: image)
      metadata&.untrack_usage(self)
    end
  end
  
  def extract_image_urls_from_content
    # Markdownから画像URLを抽出
    content.scan(/!\[.*?\]\((.*?)\)/).flatten
  end
end
```

#### 5. フロントエンド実装（Stimulus）

```javascript
// app/javascript/controllers/media/library_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["grid", "list", "filter", "search"]
  static values = {
    view: String,
    page: Number
  }
  
  connect() {
    this.loadMedia()
  }
  
  // 表示切り替え
  switchView(event) {
    this.viewValue = event.target.dataset.view
    this.render()
  }
  
  // 検索
  search(event) {
    const query = event.target.value
    this.loadMedia({ q: query })
  }
  
  // フィルタ適用
  applyFilter(event) {
    const filters = this.getFilters()
    this.loadMedia(filters)
  }
  
  // 画像読み込み
  async loadMedia(params = {}) {
    const response = await fetch(`/admin/media?${new URLSearchParams(params)}`)
    const data = await response.json()
    this.render(data)
  }
  
  // レンダリング
  render(data) {
    if (this.viewValue === 'grid') {
      this.renderGrid(data)
    } else {
      this.renderList(data)
    }
  }
}
```

```javascript
// app/javascript/controllers/media/upload_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropzone", "input", "progress"]
  
  connect() {
    this.setupDropzone()
  }
  
  setupDropzone() {
    const dropzone = this.dropzoneTarget
    
    dropzone.addEventListener('dragover', (e) => {
      e.preventDefault()
      dropzone.classList.add('drag-over')
    })
    
    dropzone.addEventListener('drop', (e) => {
      e.preventDefault()
      dropzone.classList.remove('drag-over')
      this.handleFiles(e.dataTransfer.files)
    })
  }
  
  async handleFiles(files) {
    const formData = new FormData()
    
    Array.from(files).forEach(file => {
      formData.append('images[]', file)
    })
    
    formData.append('generate_webp', true)
    formData.append('generate_thumbnails', true)
    
    try {
      const response = await fetch('/admin/media', {
        method: 'POST',
        headers: {
          'X-CSRF-Token': this.csrfToken
        },
        body: formData
      })
      
      const data = await response.json()
      this.handleUploadComplete(data)
    } catch (error) {
      this.handleUploadError(error)
    }
  }
  
  handleUploadComplete(data) {
    // 成功通知
    // 一覧更新
  }
}
```

#### 6. 画像編集UI（トリミング）

```javascript
// app/javascript/controllers/media/edit_controller.js
import { Controller } from "@hotwired/stimulus"
import Cropper from 'cropperjs'

export default class extends Controller {
  static targets = ["image", "preview"]
  static values = {
    mediaId: Number,
    aspectRatio: String
  }
  
  connect() {
    this.initCropper()
  }
  
  initCropper() {
    this.cropper = new Cropper(this.imageTarget, {
      aspectRatio: this.getAspectRatio(),
      viewMode: 1,
      preview: this.previewTarget
    })
  }
  
  getAspectRatio() {
    const ratios = {
      'free': NaN,
      '16:9': 16 / 9,
      '4:3': 4 / 3,
      '1:1': 1
    }
    return ratios[this.aspectRatioValue] || NaN
  }
  
  changeAspectRatio(event) {
    this.aspectRatioValue = event.target.value
    this.cropper.setAspectRatio(this.getAspectRatio())
  }
  
  rotate(degrees) {
    this.cropper.rotate(degrees)
  }
  
  flip(direction) {
    if (direction === 'horizontal') {
      this.cropper.scaleX(-this.cropper.getData().scaleX || -1)
    } else {
      this.cropper.scaleY(-this.cropper.getData().scaleY || -1)
    }
  }
  
  async save(event) {
    const cropData = this.cropper.getData()
    const saveAsNew = event.target.dataset.saveAsNew === 'true'
    
    const response = await fetch(`/admin/media/${this.mediaIdValue}/edit`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': this.csrfToken
      },
      body: JSON.stringify({
        operation: 'crop',
        params: {
          x: Math.round(cropData.x),
          y: Math.round(cropData.y),
          width: Math.round(cropData.width),
          height: Math.round(cropData.height)
        },
        save_as_new: saveAsNew
      })
    })
    
    const data = await response.json()
    this.handleSaveComplete(data)
  }
}
```

### 必要なGem

```ruby
# Gemfile
gem 'image_processing', '~> 1.12'  # 画像処理
gem 'mini_magick', '~> 4.12'       # ImageMagick wrapper
gem 'ruby-vips', '~> 2.1'          # 高速画像処理（オプション）
```

### 必要なJavaScriptライブラリ

```json
// package.json
{
  "dependencies": {
    "cropperjs": "^1.6.0",
    "dropzone": "^6.0.0"
  }
}
```

---

## 📊 実装履歴

| 日付 | 担当 | 内容 |
|------|------|------|
| 2024-12-26 | Kiro | 初版作成（Phase5.1実装待ち） |

---

## 🔗 関連ドキュメント

- Phase計画書: `/docs/development/phase_plan_rails_8_1_1.md`
- 総合仕様書: `/docs/specifications/spec.md`
- Phase 4画像アップロード: `/docs/specifications/features/phase4_image_caption.md`
- Active Storage公式ドキュメント: https://edgeguides.rubyonrails.org/active_storage_overview.html

---

## 📝 補足

### Phase 4との違い

| 機能 | Phase 4（記事編集内） | Phase 5（メディアライブラリ） |
|------|---------------------|---------------------------|
| アップロード | 記事編集画面から | 専用管理画面から |
| 画像管理 | 記事ごと | 一元管理 |
| 検索・フィルタ | ❌ | ✅ |
| 画像編集 | ❌ | ✅（トリミング・回転） |
| 使用状況確認 | ❌ | ✅ |
| 一括操作 | ❌ | ✅ |
| WebP変換 | ❌ | ✅ |

### 実装優先度
Phase 5.1での実装を予定。Phase 4完了後に着手する。

### 技術的制約
- Active Storageを基盤として使用
- ImageMagick or libvipsが必要
- 大量画像処理は非同期ジョブで実行
- サムネイル生成はSidekiqで処理

### パフォーマンス考慮事項
- サムネイル生成は非同期処理
- 画像一覧はページネーション必須
- Eager LoadingでN+1クエリ回避
- CDN使用を推奨（本番環境）

### セキュリティ考慮事項
- ファイル形式の厳密なチェック
- ファイルサイズ制限の実装
- 管理者権限の確認
- CSRF対策
- XSS対策（ファイル名のエスケープ）

### UI/UXの重要ポイント
- ドラッグ&ドロップの直感的な操作
- アップロード進捗の可視化
- 画像編集のリアルタイムプレビュー
- レスポンシブ対応（モバイルでも使いやすく）
- キーボードショートカット対応

### 将来の拡張可能性
- 動画ファイル対応
- PDFファイル対応
- フォルダ機能（カテゴリ分け）
- タグ付け機能
- 画像のバージョン管理
- 画像の共有機能
- 外部ストレージ連携（S3, GCS等）
