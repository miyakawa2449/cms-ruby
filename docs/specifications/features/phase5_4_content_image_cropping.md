# Phase 5.4: 本文内画像のトリミング機能 仕様書

## 📅 作成日・更新日
- **作成日**: 2025-01-14
- **最終更新**: 2025-01-14
- **ステータス**: 🟡 仕様策定中

---

## 🎯 概要

### 目的
ブログ記事の本文内に挿入する画像に対して、アップロード時にトリミング機能を提供する。
固定サイズ（800x600px、4:3アスペクト比）でトリミングすることで、記事内の画像サイズを統一し、
読みやすく美しいレイアウトを実現する。

### 背景
- 現在、サムネイル画像にはトリミング機能があるが、本文内画像にはない
- 本文内画像のサイズがバラバラで、レイアウトが不統一
- 大きすぎる画像がページ表示速度を低下させている
- 記事保存前でも画像をアップロードできる一時アップロード方式を採用

### ユーザーストーリー
- 執筆者として、本文内画像をトリミングしたい、なぜなら記事のレイアウトを統一したいから
- 執筆者として、画像サイズを最適化したい、なぜなら読み込み速度を改善したいから
- 執筆者として、記事保存前に画像をアップロードしたい、なぜなら執筆中にプレビューを確認したいから
- 執筆者として、トリミング範囲をプレビューしたい、なぜなら最適な構図を選びたいから

---

## ✅ 要件

### 機能要件

#### 1. 画像アップロード時のトリミング
- [ ] 画像選択時に自動的にトリミングモーダルを表示
- [ ] 4:3のアスペクト比で固定
- [ ] トリミング範囲の選択（ドラッグ&リサイズ）
- [ ] リアルタイムプレビュー表示
- [ ] トリミング後の画像サイズ：800x600px

#### 2. 一時アップロード方式
- [ ] 記事保存前でも画像をアップロード可能
- [ ] Active Storageを使用した一時保存
- [ ] 記事に紐付けて保存（content_images）
- [ ] 記事削除時に関連画像も削除

#### 3. トリミングUI
- [ ] Cropper.jsを使用したインタラクティブなUI
- [ ] トリミング範囲の視覚的な表示
- [ ] プレビュー画像の表示（800x600px）
- [ ] 保存/キャンセルボタン
- [ ] ローディング表示

#### 4. 画像の挿入
- [ ] トリミング完了後、Markdownコードを自動生成
- [ ] alt属性の入力フィールド
- [ ] キャプションの入力フィールド（オプション）
- [ ] エディタのカーソル位置に自動挿入

#### 5. エラーハンドリング
- [ ] ファイル形式チェック（JPEG, PNG, GIF, WebP）
- [ ] ファイルサイズ制限（10MB）
- [ ] アップロード失敗時のエラーメッセージ
- [ ] ネットワークエラー時のリトライ機能

### 非機能要件

#### パフォーマンス
- トリミングモーダル表示 < 1秒
- 画像アップロード < 5秒（5MB画像の場合）
- プレビュー更新 < 0.5秒

#### ユーザビリティ
- 直感的なトリミング操作
- リアルタイムプレビュー
- キーボードショートカット対応（ESC: キャンセル、Enter: 保存）
- レスポンシブ対応（モバイルでも操作可能）

#### セキュリティ
- ファイル形式の厳密なチェック
- ファイルサイズ制限の実装
- XSS対策（alt属性、キャプションのエスケープ）
- CSRF対策

#### アクセシビリティ
- キーボード操作対応
- スクリーンリーダー対応
- 適切なARIAラベル

---

## 🖼️ 画面仕様

### UI/UX詳細

#### 画像アップロードフロー

```
1. 記事編集画面で「画像を挿入」ボタンをクリック
   ↓
2. ファイル選択ダイアログが表示
   ↓
3. 画像を選択
   ↓
4. トリミングモーダルが自動表示
   ↓
5. トリミング範囲を調整
   ↓
6. プレビューを確認
   ↓
7. alt属性・キャプションを入力
   ↓
8. 「保存」ボタンをクリック
   ↓
9. 画像がアップロードされ、Markdownコードが挿入される
```

#### トリミングモーダル

```
┌─────────────────────────────────────────────────────────────┐
│ 本文内画像のトリミング                            [✕ 閉じる] │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ ┌─────────────────────────┐  ┌─────────────────────────┐ │
│ │                         │  │                         │ │
│ │                         │  │                         │ │
│ │   [トリミング範囲]       │  │   [プレビュー]          │ │
│ │                         │  │   800x600px            │ │
│ │                         │  │                         │ │
│ │                         │  │                         │ │
│ └─────────────────────────┘  └─────────────────────────┘ │
│                                                             │
│ アスペクト比: 4:3（固定）                                   │
│ 出力サイズ: 800x600px                                       │
│                                                             │
│ alt属性（必須）                                             │
│ [画像の説明を入力してください                            ] │
│                                                             │
│ キャプション（オプション）                                  │
│ [キャプションを入力してください                          ] │
│                                                             │
│ [キャンセル] [保存してMarkdownを挿入]                       │
└─────────────────────────────────────────────────────────────┘
```

#### 記事編集画面への統合

```
┌─────────────────────────────────────────────────────────────┐
│ 記事編集                                                    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ タイトル                                                    │
│ [記事タイトル                                            ] │
│                                                             │
│ 本文（Markdown）                                            │
│ ┌─────────────────────────────────────────────────────┐   │
│ │ # 見出し                                            │   │
│ │                                                     │   │
│ │ 本文テキスト...                                     │   │
│ │                                                     │   │
│ │ [📷 画像を挿入]  ← このボタンをクリック              │   │
│ │                                                     │   │
│ └─────────────────────────────────────────────────────┘   │
│                                                             │
│ [保存] [プレビュー]                                         │
└─────────────────────────────────────────────────────────────┘
```

---

## 🗄️ データ仕様

### 使用するモデル

#### Article（既存）
```ruby
class Article < ApplicationRecord
  has_many_attached :content_images
  # 本文内画像を保存
end
```

#### MediaMetadata（既存）
```ruby
class MediaMetadata < ApplicationRecord
  belongs_to :blob, class_name: 'ActiveStorage::Blob'
  
  # 画像メタデータ
  # - alt_text: string
  # - width: integer
  # - height: integer
  # - mime_type: string
  # - file_size: integer
  # - usage_count: integer
end
```

### データフロー

```
1. ユーザーが画像を選択
   ↓
2. ブラウザでFileReaderを使用して画像を読み込み
   ↓
3. トリミングモーダルを表示
   ↓
4. ユーザーがトリミング範囲を調整
   ↓
5. 「保存」ボタンをクリック
   ↓
6. Cropper.jsでトリミング後の画像をBlobとして生成
   ↓
7. FormDataを作成してサーバーに送信
   ↓
8. サーバー側でActive Storageに保存
   ↓
9. MediaMetadataレコードを作成
   ↓
10. 画像URLとMarkdownコードを返却
   ↓
11. エディタに自動挿入
```

### 画像サイズ仕様

| 用途 | サイズ | アスペクト比 | 品質 |
|------|--------|-------------|------|
| 本文内表示 | 800x600px | 4:3 | 92% |

---

## 🔌 API仕様

### エンドポイント

```
POST /admin/articles/:article_id/images
```

### リクエスト

**Content-Type**: `multipart/form-data`

**パラメータ**:
```
image: File (必須) - トリミング済み画像
alt_text: String (必須) - alt属性
caption: String (オプション) - キャプション
```

### レスポンス

**成功時（200 OK）**:
```json
{
  "success": true,
  "markdown": "![画像の説明](https://example.com/image.jpg)",
  "url": "https://example.com/image.jpg",
  "alt_text": "画像の説明",
  "caption": null,
  "filename": "image.jpg",
  "width": 800,
  "height": 600
}
```

**キャプション付きの場合**:
```json
{
  "success": true,
  "markdown": "<figure class=\"article-image\">\n  <img src=\"https://example.com/image.jpg\" alt=\"画像の説明\" />\n  <figcaption>キャプション</figcaption>\n</figure>",
  "url": "https://example.com/image.jpg",
  "alt_text": "画像の説明",
  "caption": "キャプション",
  "filename": "image.jpg",
  "width": 800,
  "height": 600
}
```

**エラー時（422 Unprocessable Entity）**:
```json
{
  "success": false,
  "error": "画像ファイルが選択されていません"
}
```

**エラー時（500 Internal Server Error）**:
```json
{
  "success": false,
  "error": "エラーが発生しました: [詳細メッセージ]"
}
```

---

## 🧪 受け入れ基準

実装完了の判断基準：

### トリミング機能
- [ ] 画像選択時にトリミングモーダルが自動表示される
- [ ] 4:3のアスペクト比で固定されている
- [ ] トリミング範囲をドラッグ&リサイズできる
- [ ] リアルタイムでプレビューが更新される
- [ ] トリミング後の画像サイズが800x600pxである

### 画像アップロード
- [ ] トリミング済み画像がサーバーにアップロードされる
- [ ] Active Storageに正しく保存される
- [ ] MediaMetadataレコードが作成される
- [ ] 画像URLが正しく生成される

### Markdown挿入
- [ ] alt属性が必須入力である
- [ ] キャプションがオプション入力である
- [ ] キャプションなしの場合、Markdown形式で挿入される
- [ ] キャプションありの場合、HTML形式（figure/figcaption）で挿入される
- [ ] エディタのカーソル位置に正しく挿入される

### エラーハンドリング
- [ ] 画像以外のファイルを選択した場合、エラーメッセージが表示される
- [ ] 10MB以上のファイルを選択した場合、エラーメッセージが表示される
- [ ] アップロード失敗時、適切なエラーメッセージが表示される
- [ ] ネットワークエラー時、リトライ可能である

### UI/UX
- [ ] モーダルの表示/非表示がスムーズである
- [ ] ローディング表示が適切に表示される
- [ ] ESCキーでモーダルを閉じられる
- [ ] モバイルでも操作可能である
- [ ] レスポンシブデザインが適切に動作する

### パフォーマンス
- [ ] トリミングモーダル表示が1秒以内
- [ ] 画像アップロードが5秒以内（5MB画像）
- [ ] プレビュー更新が0.5秒以内

### セキュリティ
- [ ] ファイル形式が厳密にチェックされる
- [ ] ファイルサイズ制限が機能する
- [ ] alt属性とキャプションがHTMLエスケープされる
- [ ] CSRF対策が実装されている

---

## 🧪 テスト仕様

### TDD適用判断

- [x] TDD適用: はい
- **理由**: 画像処理、ファイルアップロード、セキュリティなど重要な機能が多いため

### テスト対象

| 対象 | ファイルパス | テストファイルパス |
|------|-------------|-------------------|
| Controller | `app/controllers/admin/article_images_controller.rb` | `spec/controllers/admin/article_images_controller_spec.rb` |
| JavaScript | `app/javascript/controllers/content_image_editor_controller.js` | `spec/javascript/controllers/content_image_editor_controller.spec.js` |
| Model | `app/models/media_metadata.rb` | `spec/models/media_metadata_spec.rb` |

### Controller: Admin::ArticleImagesController

#### describe '#create'

**正常系**:
- [ ] トリミング済み画像をアップロードできる
- [ ] MediaMetadataレコードが作成される
- [ ] 画像URLが正しく生成される
- [ ] alt属性が保存される
- [ ] キャプションなしの場合、Markdown形式で返却される
- [ ] キャプションありの場合、HTML形式で返却される

**異常系**:
- [ ] 画像ファイルが選択されていない場合、エラーを返す
- [ ] 不正なファイル形式の場合、エラーを返す
- [ ] ファイルサイズ超過の場合、エラーを返す
- [ ] アップロード失敗時、適切なエラーメッセージを返す

### JavaScript: ContentImageEditorController

#### describe 'トリミング機能'

**正常系**:
- [ ] ファイル選択時にモーダルが表示される
- [ ] Cropperが4:3で初期化される
- [ ] トリミング範囲を変更できる
- [ ] プレビューが更新される
- [ ] 保存時に800x600pxのBlobが生成される

**異常系**:
- [ ] 画像以外のファイルを選択した場合、エラーメッセージを表示する
- [ ] Blob生成失敗時、エラーメッセージを表示する

### テストコード例

```ruby
# spec/controllers/admin/article_images_controller_spec.rb
require 'rails_helper'

RSpec.describe Admin::ArticleImagesController, type: :controller do
  let(:admin_user) { create(:admin_user) }
  let(:article) { create(:article, admin_user: admin_user) }
  let(:image_file) { fixture_file_upload('spec/fixtures/files/test_image.jpg', 'image/jpeg') }
  
  before do
    sign_in admin_user
  end
  
  describe 'POST #create' do
    context '正常系' do
      it 'トリミング済み画像をアップロードできる' do
        expect {
          post :create, params: {
            article_id: article.id,
            image: image_file,
            alt_text: 'テスト画像'
          }
        }.to change(ActiveStorage::Attachment, :count).by(1)
        
        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['alt_text']).to eq('テスト画像')
      end
      
      it 'MediaMetadataレコードが作成される' do
        expect {
          post :create, params: {
            article_id: article.id,
            image: image_file,
            alt_text: 'テスト画像'
          }
        }.to change(MediaMetadata, :count).by(1)
        
        metadata = MediaMetadata.last
        expect(metadata.alt_text).to eq('テスト画像')
        expect(metadata.width).to eq(800)
        expect(metadata.height).to eq(600)
      end
      
      it 'キャプションなしの場合、Markdown形式で返却される' do
        post :create, params: {
          article_id: article.id,
          image: image_file,
          alt_text: 'テスト画像'
        }
        
        json = JSON.parse(response.body)
        expect(json['markdown']).to match(/!\[テスト画像\]\(.*\)/)
      end
      
      it 'キャプションありの場合、HTML形式で返却される' do
        post :create, params: {
          article_id: article.id,
          image: image_file,
          alt_text: 'テスト画像',
          caption: 'テストキャプション'
        }
        
        json = JSON.parse(response.body)
        expect(json['markdown']).to include('<figure class="article-image">')
        expect(json['markdown']).to include('<figcaption>テストキャプション</figcaption>')
      end
    end
    
    context '異常系' do
      it '画像ファイルが選択されていない場合、エラーを返す' do
        post :create, params: {
          article_id: article.id,
          alt_text: 'テスト画像'
        }
        
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['error']).to include('画像ファイルが選択されていません')
      end
      
      it '不正なファイル形式の場合、エラーを返す' do
        invalid_file = fixture_file_upload('spec/fixtures/files/test.txt', 'text/plain')
        
        post :create, params: {
          article_id: article.id,
          image: invalid_file,
          alt_text: 'テスト画像'
        }
        
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
```

### テストデータ（FactoryBot）

```ruby
# spec/factories/media_metadata.rb
FactoryBot.define do
  factory :media_metadata do
    association :blob, factory: :active_storage_blob
    alt_text { 'テスト画像' }
    width { 800 }
    height { 600 }
    mime_type { 'image/jpeg' }
    file_size { 102400 }
    usage_count { 0 }
  end
end
```

### テストフィクスチャ

```
# spec/fixtures/files/
test_image.jpg      # 1200x900px, 500KB（トリミング前）
test_image_large.jpg # 3000x2000px, 5MB（大きいファイル）
test.txt            # テキストファイル（不正なファイル形式テスト用）
```

### カバレッジ目標

- Controller: 90%以上
- JavaScript: 80%以上（手動テストも併用）
- Model: 95%以上

---

## 💡 実装メモ

### 実装対象ファイル

#### バックエンド

1. **コントローラー**: `app/controllers/admin/article_images_controller.rb`（既存を拡張）
   - トリミング済み画像の受け取り
   - Active Storageへの保存
   - MediaMetadataの作成
   - Markdownコードの生成

#### フロントエンド

1. **JavaScript**: `app/javascript/controllers/content_image_editor_controller.js`（新規作成）
   - ファイル選択時の処理
   - トリミングモーダルの表示
   - Cropper.jsの初期化
   - トリミング処理
   - サーバーへのアップロード

2. **ビュー**: `app/views/admin/articles/_content_image_editor_modal.html.erb`（新規作成）
   - トリミングモーダルのHTML
   - プレビュー表示
   - フォーム要素

3. **ビュー**: `app/views/admin/articles/_form.html.erb`（既存を拡張）
   - 画像挿入ボタンの追加
   - モーダルの読み込み

### 実装アプローチ

#### 1. サムネイル編集機能との共通化

既存の`thumbnail_editor_controller.js`と共通のロジックを抽出：

```javascript
// 共通化できる部分
- Cropperの初期化
- プレビュー更新
- Blob生成
- モーダル制御
```

#### 2. トリミングサイズの違い

| 機能 | サイズ | アスペクト比 |
|------|--------|-------------|
| サムネイル | 1200x900px | 4:3 |
| 本文内画像 | 800x600px | 4:3 |

#### 3. Cropper.js設定

```javascript
// 本文内画像用の設定
{
  viewMode: 1,
  dragMode: 'move',
  aspectRatio: 4 / 3,  // 固定
  autoCropArea: 0.9,
  restore: false,
  guides: true,
  center: true,
  highlight: false,
  cropBoxMovable: true,
  cropBoxResizable: true,
  toggleDragModeOnDblclick: false
}
```

#### 4. 画像サイズ生成

```javascript
// 800x600pxのBlobを生成
const canvas = cropper.getCroppedCanvas({
  width: 800,
  height: 600,
  imageSmoothingEnabled: true,
  imageSmoothingQuality: 'high'
})

canvas.toBlob(blob => {
  // アップロード処理
}, 'image/jpeg', 0.92)
```

### 必要なライブラリ

既存のライブラリを使用：

```json
// package.json（既存）
{
  "dependencies": {
    "cropperjs": "^1.6.0"
  }
}
```

### 技術的制約

- Rails 8.1.1
- Active Storage
- Stimulus.js
- Cropper.js 1.6.0
- Tailwind CSS

### パフォーマンス考慮事項

- 画像のクライアント側処理（トリミング）
- 最適化された画像サイズ（800x600px）
- JPEG品質92%でファイルサイズを抑制
- 非同期アップロード

### セキュリティ考慮事項

- ファイル形式の厳密なチェック（MIMEタイプ）
- ファイルサイズ制限（10MB）
- XSS対策（alt属性、キャプションのHTMLエスケープ）
- CSRF対策（Rails標準）
- 管理者権限チェック

### UI/UXの重要ポイント

- トリミング操作の直感性
- リアルタイムプレビュー
- ローディング表示
- エラーメッセージの分かりやすさ
- キーボードショートカット
- レスポンシブ対応

---

## 📊 実装履歴

| 日付 | 担当 | 内容 |
|------|------|------|
| 2025-01-14 | Kiro | 初版作成（Phase5.4仕様策定） |

---

## 🔗 関連ドキュメント

- Phase 5メディアライブラリ: `/docs/specifications/features/phase5_media_library.md`
- Phase 4画像キャプション: `/docs/specifications/features/phase4_image_caption.md`
- サムネイル編集機能: `app/javascript/controllers/thumbnail_editor_controller.js`
- Active Storage公式ドキュメント: https://edgeguides.rubyonrails.org/active_storage_overview.html
- Cropper.js公式ドキュメント: https://github.com/fengyuanchen/cropperjs

---

## 📝 補足

### サムネイル編集機能との違い

| 項目 | サムネイル | 本文内画像 |
|------|-----------|-----------|
| 用途 | 記事のサムネイル | 記事本文内の画像 |
| サイズ | 1200x900px | 800x600px |
| 複数サイズ生成 | あり（記事用・OGP用・サムネイル用） | なし（1サイズのみ） |
| アスペクト比選択 | あり（4:3, 3:2, 16:9） | なし（4:3固定） |
| 保存先 | thumbnail_image | content_images |

### 実装優先度

Phase 5.4として、Phase 5.1（メディアライブラリ）より先に実装予定。

### 将来の拡張可能性

- 複数サイズの自動生成（レスポンシブ対応）
- WebP形式への自動変換
- 画像の遅延読み込み（Lazy Loading）
- 画像の圧縮率調整
- アスペクト比の選択肢追加
- 画像の回転・反転機能
- 画像のフィルター機能

### 既知の制限事項

- アスペクト比は4:3固定
- 出力サイズは800x600px固定
- 1つの画像につき1サイズのみ生成
- トリミング後の再編集は不可（再アップロードが必要）

### 参考実装

既存のサムネイル編集機能（`thumbnail_editor_controller.js`）を参考に実装。
主な違いは出力サイズとアスペクト比の固定化。
