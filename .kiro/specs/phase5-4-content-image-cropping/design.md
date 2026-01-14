# Phase 5.4: 本文内画像トリミング機能 - 設計書

## アーキテクチャ概要

```
┌─────────────────────────────────────────────────────────────┐
│                        ブラウザ                              │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  記事編集画面                                                │
│  ├─ 画像挿入ボタン                                          │
│  └─ Markdownエディタ                                        │
│                                                             │
│  ContentImageEditorController (Stimulus)                    │
│  ├─ ファイル選択処理                                        │
│  ├─ モーダル表示制御                                        │
│  ├─ Cropper.js初期化                                        │
│  ├─ トリミング処理                                          │
│  ├─ プレビュー更新                                          │
│  └─ サーバーへのアップロード                                │
│                                                             │
│  トリミングモーダル                                          │
│  ├─ トリミング範囲選択エリア                                │
│  ├─ プレビュー表示                                          │
│  ├─ alt属性入力フィールド                                   │
│  ├─ キャプション入力フィールド                              │
│  └─ 保存/キャンセルボタン                                   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                            ↓ HTTP POST
┌─────────────────────────────────────────────────────────────┐
│                        サーバー                              │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Admin::ArticleImagesController                             │
│  └─ create アクション                                       │
│      ├─ 画像ファイル受け取り                                │
│      ├─ Active Storageに保存                                │
│      ├─ MediaMetadata作成                                   │
│      └─ Markdownコード生成                                  │
│                                                             │
│  Active Storage                                             │
│  └─ content_images (has_many_attached)                      │
│                                                             │
│  MediaMetadata Model                                        │
│  ├─ alt_text                                                │
│  ├─ width (800)                                             │
│  ├─ height (600)                                            │
│  ├─ mime_type                                               │
│  └─ file_size                                               │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## コンポーネント設計

### 1. フロントエンド

#### 1.1 ContentImageEditorController (Stimulus)

**責務**:
- ファイル選択時の処理
- トリミングモーダルの表示/非表示制御
- Cropper.jsの初期化と制御
- トリミング処理
- プレビュー更新
- サーバーへのアップロード
- Markdownコードの挿入

**主要メソッド**:
```javascript
class ContentImageEditorController extends Controller {
  // ターゲット
  static targets = [
    "modal",
    "cropperContainer",
    "fileInput",
    "preview",
    "altInput",
    "captionInput",
    "saveBtn"
  ]
  
  // ファイル選択時
  selectFile(event)
  
  // モーダルを開く
  openModal(file)
  
  // Cropperを初期化
  initCropper(imageUrl)
  
  // プレビューを更新
  updatePreview()
  
  // 保存処理
  async save()
  
  // 800x600pxのBlobを取得
  async getImageBlob()
  
  // サーバーにアップロード
  async uploadImage(blob, altText, caption)
  
  // Markdownを挿入
  insertMarkdown(markdown)
  
  // モーダルを閉じる
  close()
  
  // Cropperを破棄
  destroyCropper()
  
  // エラーメッセージ表示
  showError(message)
  
  // 成功メッセージ表示
  showSuccess(message)
}
```

**Cropper.js設定**:
```javascript
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
  toggleDragModeOnDblclick: false,
  crop: () => {
    this.updatePreview()
  }
}
```

**画像生成処理**:
```javascript
// 800x600pxのBlobを生成
const canvas = cropper.getCroppedCanvas({
  width: 800,
  height: 600,
  imageSmoothingEnabled: true,
  imageSmoothingQuality: 'high'
})

return new Promise((resolve, reject) => {
  canvas.toBlob(
    blob => blob ? resolve(blob) : reject(new Error("変換失敗")),
    'image/jpeg',
    0.92
  )
})
```

#### 1.2 トリミングモーダル (Partial View)

**ファイル**: `app/views/admin/articles/_content_image_editor_modal.html.erb`

**構造**:
```erb
<div data-controller="content-image-editor" 
     data-content-image-editor-target="modal"
     class="hidden fixed inset-0 z-50">
  
  <!-- オーバーレイ -->
  <div class="fixed inset-0 bg-black bg-opacity-75"></div>
  
  <!-- モーダルコンテンツ -->
  <div class="relative bg-white rounded-lg max-w-4xl">
    
    <!-- ヘッダー -->
    <div class="px-6 py-4 border-b">
      <h3>本文内画像のトリミング</h3>
      <button data-action="click->content-image-editor#close">×</button>
    </div>
    
    <!-- コンテンツ -->
    <div class="p-6 grid grid-cols-2 gap-6">
      
      <!-- 左側: トリミング範囲選択 -->
      <div>
        <h4>トリミング範囲</h4>
        <div data-content-image-editor-target="cropperContainer"></div>
        <p>アスペクト比: 4:3（固定）</p>
        <p>出力サイズ: 800x600px</p>
      </div>
      
      <!-- 右側: プレビュー -->
      <div>
        <h4>プレビュー</h4>
        <img data-content-image-editor-target="preview" />
        <p>800x600px</p>
      </div>
    </div>
    
    <!-- フォーム -->
    <div class="px-6 pb-4">
      <label>alt属性（必須）</label>
      <input data-content-image-editor-target="altInput" required />
      
      <label>キャプション（オプション）</label>
      <input data-content-image-editor-target="captionInput" />
    </div>
    
    <!-- フッター -->
    <div class="px-6 py-4 border-t">
      <button data-action="click->content-image-editor#close">
        キャンセル
      </button>
      <button data-action="click->content-image-editor#save"
              data-content-image-editor-target="saveBtn">
        保存してMarkdownを挿入
      </button>
    </div>
  </div>
</div>
```

#### 1.3 記事編集画面への統合

**ファイル**: `app/views/admin/articles/_form.html.erb`

**追加要素**:
```erb
<!-- 画像挿入ボタン -->
<div class="mb-4">
  <label>本文（Markdown）</label>
  <div class="flex gap-2 mb-2">
    <button type="button"
            data-controller="content-image-editor"
            data-action="click->content-image-editor#openFileDialog"
            class="btn btn-secondary">
      📷 画像を挿入
    </button>
  </div>
  
  <!-- 非表示のファイル入力 -->
  <input type="file"
         accept="image/*"
         data-content-image-editor-target="fileInput"
         data-action="change->content-image-editor#selectFile"
         class="hidden" />
  
  <!-- Markdownエディタ -->
  <%= form.text_area :content, id: "article_content" %>
</div>

<!-- トリミングモーダル -->
<%= render 'content_image_editor_modal' %>
```

### 2. バックエンド

#### 2.1 Admin::ArticleImagesController

**ファイル**: `app/controllers/admin/article_images_controller.rb`

**拡張内容**:
```ruby
class Admin::ArticleImagesController < Admin::BaseController
  # POST /admin/articles/:article_id/images
  def create
    @article = Article.find(params[:article_id])

    # バリデーション
    return render_error('画像ファイルが選択されていません') unless params[:image].present?
    return render_error('alt属性は必須です') unless params[:alt_text].present?
    
    # ファイル形式チェック
    unless valid_image_format?(params[:image])
      return render_error('対応していないファイル形式です')
    end
    
    # ファイルサイズチェック
    if params[:image].size > 10.megabytes
      return render_error('ファイルサイズは10MB以下にしてください')
    end

    # Active Storageに画像を添付
    @article.content_images.attach(params[:image])
    image = @article.content_images.last

    if image.present?
      # MediaMetadataを作成
      metadata = create_media_metadata(image, params[:alt_text])
      
      # 画像URLを生成
      image_url = url_for(image)
      
      # Markdownコードを生成
      markdown = generate_markdown(image_url, params[:alt_text], params[:caption])

      render json: {
        success: true,
        markdown: markdown,
        url: image_url,
        alt_text: params[:alt_text],
        caption: params[:caption],
        filename: image.filename.to_s,
        width: 800,
        height: 600
      }
    else
      render_error('画像のアップロードに失敗しました')
    end
  rescue => e
    Rails.logger.error "Article image upload error: #{e.message}"
    render_error("エラーが発生しました: #{e.message}")
  end

  private

  def valid_image_format?(file)
    %w[image/jpeg image/png image/gif image/webp].include?(file.content_type)
  end

  def create_media_metadata(image, alt_text)
    MediaMetadata.find_or_create_by(blob: image.blob) do |m|
      m.alt_text = alt_text
      m.mime_type = image.blob.content_type
      m.file_size = image.blob.byte_size
      m.width = 800
      m.height = 600
    end.tap do |metadata|
      metadata.update(alt_text: alt_text)
      metadata.track_usage
    end
  end

  def generate_markdown(image_url, alt_text, caption)
    if caption.present?
      # XSS対策: HTMLエスケープ
      escaped_alt = ERB::Util.html_escape(alt_text)
      escaped_caption = ERB::Util.html_escape(caption)

      <<~HTML.strip
        <figure class="article-image">
          <img src="#{image_url}" alt="#{escaped_alt}" />
          <figcaption>#{escaped_caption}</figcaption>
        </figure>
      HTML
    else
      # キャプションなしの場合はMarkdown形式
      "![#{alt_text}](#{image_url})"
    end
  end

  def render_error(message)
    render json: { success: false, error: message }, status: :unprocessable_entity
  end
end
```

#### 2.2 MediaMetadata Model

**ファイル**: `app/models/media_metadata.rb`

**既存モデルを使用**（変更なし）:
```ruby
class MediaMetadata < ApplicationRecord
  belongs_to :blob, class_name: 'ActiveStorage::Blob'
  
  # 使用状況追跡
  def track_usage
    increment!(:usage_count)
  end
  
  def untrack_usage
    decrement!(:usage_count) if usage_count > 0
  end
end
```

## データフロー

### 画像アップロードフロー

```
1. ユーザーが「画像を挿入」ボタンをクリック
   ↓
2. ファイル選択ダイアログが表示される
   ↓
3. ユーザーが画像を選択
   ↓
4. ContentImageEditorController.selectFile()が呼ばれる
   ↓
5. ファイル形式をチェック（クライアント側）
   ↓
6. FileReaderで画像を読み込み
   ↓
7. トリミングモーダルを表示
   ↓
8. Cropper.jsを初期化（4:3固定）
   ↓
9. ユーザーがトリミング範囲を調整
   ↓
10. プレビューがリアルタイムで更新される
   ↓
11. ユーザーがalt属性・キャプションを入力
   ↓
12. 「保存」ボタンをクリック
   ↓
13. Cropper.jsで800x600pxのBlobを生成
   ↓
14. FormDataを作成
   ↓
15. サーバーにPOSTリクエスト
   ↓
16. Admin::ArticleImagesController.createが処理
   ↓
17. バリデーション（ファイル形式・サイズ）
   ↓
18. Active Storageに保存
   ↓
19. MediaMetadataレコード作成
   ↓
20. Markdownコード生成
   ↓
21. JSONレスポンス返却
   ↓
22. クライアント側でMarkdownをエディタに挿入
   ↓
23. モーダルを閉じる
   ↓
24. 成功メッセージを表示
```

## API設計

### エンドポイント

```
POST /admin/articles/:article_id/images
```

### リクエスト

**Content-Type**: `multipart/form-data`

**パラメータ**:
| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| image | File | ✓ | トリミング済み画像（800x600px） |
| alt_text | String | ✓ | alt属性 |
| caption | String | - | キャプション |

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

**エラー時（422 Unprocessable Entity）**:
```json
{
  "success": false,
  "error": "エラーメッセージ"
}
```

## セキュリティ設計

### 1. ファイル形式チェック

**クライアント側**:
```javascript
if (!file.type.startsWith('image/')) {
  this.showError('画像ファイルを選択してください')
  return
}
```

**サーバー側**:
```ruby
def valid_image_format?(file)
  %w[image/jpeg image/png image/gif image/webp].include?(file.content_type)
end
```

### 2. ファイルサイズ制限

**クライアント側**:
```javascript
if (file.size > 10 * 1024 * 1024) {
  this.showError('ファイルサイズは10MB以下にしてください')
  return
}
```

**サーバー側**:
```ruby
if params[:image].size > 10.megabytes
  return render_error('ファイルサイズは10MB以下にしてください')
end
```

### 3. XSS対策

```ruby
def generate_markdown(image_url, alt_text, caption)
  if caption.present?
    escaped_alt = ERB::Util.html_escape(alt_text)
    escaped_caption = ERB::Util.html_escape(caption)
    # ...
  end
end
```

### 4. CSRF対策

Railsの標準CSRF対策を使用:
```javascript
fetch(url, {
  method: 'POST',
  headers: {
    'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
  },
  body: formData
})
```

## エラーハンドリング

### クライアント側エラー

| エラー | 条件 | メッセージ |
|--------|------|-----------|
| ファイル形式エラー | 画像以外のファイル | 「画像ファイルを選択してください」 |
| ファイルサイズエラー | 10MB超過 | 「ファイルサイズは10MB以下にしてください」 |
| Blob生成エラー | Canvas変換失敗 | 「画像の変換に失敗しました」 |
| アップロードエラー | ネットワークエラー | 「アップロードに失敗しました。もう一度お試しください」 |

### サーバー側エラー

| エラー | 条件 | HTTPステータス |
|--------|------|---------------|
| パラメータエラー | 必須パラメータ不足 | 422 |
| ファイル形式エラー | 非対応形式 | 422 |
| ファイルサイズエラー | 10MB超過 | 422 |
| アップロードエラー | Active Storage失敗 | 422 |
| サーバーエラー | 予期しないエラー | 500 |

## パフォーマンス最適化

### 1. 画像サイズの最適化
- 出力サイズ: 800x600px（固定）
- JPEG品質: 92%
- ファイルサイズ目安: 100-200KB

### 2. クライアント側処理
- トリミングはクライアント側で実行
- サーバーへの負荷を軽減

### 3. 非同期アップロード
- Fetch APIを使用した非同期通信
- ローディング表示でUX向上

## テスト戦略

### 1. 単体テスト

**Controller**:
- 正常系: 画像アップロード成功
- 異常系: パラメータエラー、ファイル形式エラー、サイズエラー

**Model**:
- MediaMetadata作成
- 使用状況追跡

### 2. 統合テスト

**JavaScript**:
- ファイル選択からモーダル表示
- トリミング操作
- プレビュー更新
- アップロード処理

### 3. E2Eテスト

- 画像選択からMarkdown挿入までの一連の流れ

## 実装の優先順位

### Phase 1: 基本機能（必須）
1. ContentImageEditorController作成
2. トリミングモーダルのHTML作成
3. Cropper.js統合
4. 画像アップロード処理
5. Markdown挿入機能

### Phase 2: エラーハンドリング（必須）
1. ファイル形式チェック
2. ファイルサイズチェック
3. エラーメッセージ表示

### Phase 3: UI/UX改善（推奨）
1. ローディング表示
2. 成功メッセージ表示
3. キーボードショートカット
4. レスポンシブ対応

## 既存機能との統合

### サムネイル編集機能との共通化

**共通ロジック**:
- Cropperの初期化
- プレビュー更新
- Blob生成
- モーダル制御

**差異**:
| 項目 | サムネイル | 本文内画像 |
|------|-----------|-----------|
| 出力サイズ | 1200x900px | 800x600px |
| 複数サイズ | あり | なし |
| アスペクト比選択 | あり | なし（4:3固定） |
| 保存先 | thumbnail_image | content_images |

**実装方針**:
- 別々のControllerとして実装（共通化は将来の課題）
- サムネイル編集機能のコードを参考にする
