# 記事画像キャプション機能 仕様書

## 📅 作成日・更新日
- **作成日**: 2024-12-26
- **最終更新**: 2025-12-26
- **ステータス**: ✅ 実装完了

---

## 🎯 概要

### 目的
記事内に挿入する画像に対して、alt属性だけでなくキャプション（figcaption）を追加できるようにする。
これにより、画像の詳細な説明を視覚的に表示し、読者の理解を深める。

### ユーザーストーリー
- 記事執筆者として、画像にキャプションを付けたい、なぜなら画像の詳細な説明を読者に提供したいから
- 記事執筆者として、alt属性とキャプションを使い分けたい、なぜならSEO/アクセシビリティとユーザー体験の両方を最適化したいから

---

## ✅ 要件

### 機能要件
- [ ] 画像アップロード時にキャプション入力フィールドを追加
- [ ] キャプションが入力された場合、`<figure>`と`<figcaption>`タグを使用したHTMLを生成
- [ ] キャプションが空の場合、従来通りシンプルなMarkdown形式（`![alt](url)`）で挿入
- [ ] 生成されたHTMLは記事本文（Markdown）に挿入される
- [ ] フロントエンド表示時に適切なスタイリングが適用される

### 非機能要件
- **パフォーマンス**: 画像アップロード処理に影響を与えない
- **セキュリティ**: キャプションテキストのXSS対策（HTMLエスケープ）
- **アクセシビリティ**: alt属性とfigcaptionの適切な使い分け
- **SEO**: 画像検索最適化のためのalt属性とキャプションの併用

---

## 🖼️ 画面仕様

### UI/UX詳細

#### 管理画面（記事編集フォーム）
現在の画像アップロードセクションに以下を追加：

```
📷 本文内画像アップロード
┌─────────────────────────────────────┐
│ 画像ファイル: [ファイル選択ボタン]    │
│                                     │
│ 代替テキスト（alt属性）              │
│ [画像の説明を入力してください]       │
│ ℹ️ SEO・アクセシビリティのため       │
│                                     │
│ キャプション（任意）                 │
│ [画像のキャプションを入力...]        │
│ ℹ️ 画像の下に表示される説明文です。  │
│    空欄の場合はシンプルなMarkdown    │
│    形式で挿入されます。              │
│                                     │
│ [画像をアップロードして本文に挿入]   │
└─────────────────────────────────────┘
```

#### フロントエンド表示

キャプション付き画像の表示例：

```html
<figure class="article-image">
  <img src="http://example.com/foo.jpg" alt="画像説明" />
  <figcaption>キャプション（詳細説明）</figcaption>
</figure>
```

スタイリング要件：
- 画像は中央寄せ
- キャプションは画像の下に表示、グレーの小さめのフォント
- レスポンシブ対応（モバイルでも適切に表示）

---

## 🗄️ データ仕様

### 使用するモデル
- **Article**: 既存モデル（変更なし）
- **ActiveStorage::Attachment**: 画像ファイル管理（変更なし）

### データフロー
```
1. ユーザーが画像ファイル、alt属性、キャプションを入力
2. JavaScriptがFormDataを作成してPOST
3. Railsコントローラーが画像をActive Storageに保存
4. キャプションの有無で生成するHTMLを分岐
   - キャプションあり: <figure>タグのHTML
   - キャプションなし: ![alt](url) のMarkdown
5. 生成されたコードを記事本文に挿入
```

---

## 🔌 API仕様

### エンドポイント
```
POST /admin-secure-panel-miyakawa2449/articles/:article_id/images
```

### リクエストパラメータ（変更後）
```javascript
FormData {
  image: File,           // 画像ファイル
  alt_text: String,      // alt属性（既存）
  caption: String        // キャプション（新規・任意）
}
```

### レスポンス例（キャプションあり）
```json
{
  "success": true,
  "markdown": "<figure class=\"article-image\">\n  <img src=\"http://localhost:3000/rails/active_storage/blobs/.../image.jpg\" alt=\"画像説明\" />\n  <figcaption>キャプション文</figcaption>\n</figure>",
  "url": "http://localhost:3000/rails/active_storage/blobs/.../image.jpg",
  "alt_text": "画像説明",
  "caption": "キャプション文",
  "filename": "image.jpg"
}
```

### レスポンス例（キャプションなし）
```json
{
  "success": true,
  "markdown": "![画像説明](http://localhost:3000/rails/active_storage/blobs/.../image.jpg)",
  "url": "http://localhost:3000/rails/active_storage/blobs/.../image.jpg",
  "alt_text": "画像説明",
  "caption": null,
  "filename": "image.jpg"
}
```

---

## 🧪 受け入れ基準

実装完了の判断基準：

- [x] 画像アップロードフォームにキャプション入力フィールドが追加されている
- [x] キャプションを入力して画像をアップロードすると、`<figure>`タグのHTMLが本文に挿入される
- [x] キャプションを空欄にして画像をアップロードすると、従来通りMarkdown形式で挿入される
- [x] 挿入されたHTMLのalt属性とキャプションが正しく設定されている
- [x] フロントエンドで画像とキャプションが適切にスタイリングされて表示される
- [x] キャプションテキストがHTMLエスケープされ、XSS攻撃を防げる
- [x] モバイル表示でも画像とキャプションが適切に表示される
- [x] 既存の画像アップロード機能（キャプションなし）が正常に動作する

---

## 🧪 テスト仕様

### TDD適用判断

- [x] TDD適用: はい
- **理由**: セキュリティ（XSSエスケープ）とHTML生成ロジックの正確性が重要なため

### テスト対象

| 対象 | ファイルパス | テストファイルパス |
|------|-------------|-------------------|
| Controller | `app/controllers/admin/article_images_controller.rb` | `spec/controllers/admin/article_images_controller_spec.rb` |
| JavaScript | `app/javascript/controllers/image_upload_controller.js` | `spec/javascript/controllers/image_upload_controller.spec.js` |

### Controller: Admin::ArticleImagesController

#### describe 'POST #create'

**正常系**:
- [ ] キャプション付き画像アップロードで`<figure>`タグのHTMLが生成される
- [ ] キャプションなし画像アップロードでMarkdown形式が生成される
- [ ] alt属性が正しく設定される
- [ ] 画像URLが正しく生成される
- [ ] レスポンスにmarkdown、url、alt_text、caption、filenameが含まれる

**異常系**:
- [ ] 画像ファイルがない場合、エラーレスポンスを返す
- [ ] 不正なファイル形式の場合、エラーレスポンスを返す
- [ ] 記事が存在しない場合、404エラーを返す

**セキュリティ**:
- [ ] キャプションのXSS攻撃（`<script>`タグ）がエスケープされる
- [ ] alt属性のXSS攻撃がエスケープされる
- [ ] 特殊文字（`<`, `>`, `&`, `"`, `'`）が正しくエスケープされる

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
      context 'キャプション付き画像アップロード' do
        it '<figure>タグのHTMLが生成される' do
          post :create, params: {
            article_id: article.id,
            image: image_file,
            alt_text: '画像の説明',
            caption: 'キャプション文'
          }
          
          expect(response).to have_http_status(:success)
          json = JSON.parse(response.body)
          expect(json['success']).to be true
          expect(json['markdown']).to include('<figure class="article-image">')
          expect(json['markdown']).to include('<img src=')
          expect(json['markdown']).to include('alt="画像の説明"')
          expect(json['markdown']).to include('<figcaption>キャプション文</figcaption>')
        end
        
        it 'レスポンスに必要な情報が含まれる' do
          post :create, params: {
            article_id: article.id,
            image: image_file,
            alt_text: '画像の説明',
            caption: 'キャプション文'
          }
          
          json = JSON.parse(response.body)
          expect(json).to have_key('markdown')
          expect(json).to have_key('url')
          expect(json).to have_key('alt_text')
          expect(json).to have_key('caption')
          expect(json).to have_key('filename')
          expect(json['caption']).to eq('キャプション文')
        end
      end
      
      context 'キャプションなし画像アップロード' do
        it 'Markdown形式が生成される' do
          post :create, params: {
            article_id: article.id,
            image: image_file,
            alt_text: '画像の説明',
            caption: ''
          }
          
          json = JSON.parse(response.body)
          expect(json['markdown']).to match(/!\[画像の説明\]\(.+\)/)
          expect(json['markdown']).not_to include('<figure>')
          expect(json['caption']).to be_nil
        end
      end
    end
    
    context '異常系' do
      it '画像ファイルがない場合、エラーレスポンスを返す' do
        post :create, params: {
          article_id: article.id,
          alt_text: '画像の説明'
        }
        
        expect(response).to have_http_status(:unprocessable_entity)
      end
      
      it '記事が存在しない場合、404エラーを返す' do
        post :create, params: {
          article_id: 99999,
          image: image_file,
          alt_text: '画像の説明'
        }
        
        expect(response).to have_http_status(:not_found)
      end
    end
    
    context 'セキュリティ' do
      it 'キャプションのXSS攻撃がエスケープされる' do
        post :create, params: {
          article_id: article.id,
          image: image_file,
          alt_text: '画像の説明',
          caption: '<script>alert("XSS")</script>キャプション'
        }
        
        json = JSON.parse(response.body)
        expect(json['markdown']).not_to include('<script>')
        expect(json['markdown']).to include('&lt;script&gt;')
        expect(json['markdown']).to include('&lt;/script&gt;')
      end
      
      it 'alt属性のXSS攻撃がエスケープされる' do
        post :create, params: {
          article_id: article.id,
          image: image_file,
          alt_text: '"><script>alert("XSS")</script>',
          caption: 'キャプション'
        }
        
        json = JSON.parse(response.body)
        expect(json['markdown']).not_to include('<script>')
        expect(json['markdown']).to include('&quot;&gt;&lt;script&gt;')
      end
      
      it '特殊文字が正しくエスケープされる' do
        post :create, params: {
          article_id: article.id,
          image: image_file,
          alt_text: '画像 & 説明',
          caption: 'キャプション < > " \' &'
        }
        
        json = JSON.parse(response.body)
        expect(json['markdown']).to include('&amp;')
        expect(json['markdown']).to include('&lt;')
        expect(json['markdown']).to include('&gt;')
        expect(json['markdown']).to include('&quot;')
      end
    end
  end
end
```

### テストデータ（FactoryBot）

```ruby
# spec/factories/articles.rb
FactoryBot.define do
  factory :article do
    title { 'サンプル記事' }
    content { 'サンプル本文' }
    status { 'published' }
    published_at { Time.current }
    association :admin_user
    
    trait :with_images do
      after(:create) do |article|
        article.content_images.attach(
          io: File.open(Rails.root.join('spec/fixtures/files/test_image.jpg')),
          filename: 'test_image.jpg',
          content_type: 'image/jpeg'
        )
      end
    end
  end
end

# spec/factories/admin_users.rb
FactoryBot.define do
  factory :admin_user do
    email { 'admin@example.com' }
    password { 'ADMIN_PASSWORD' }
    password_confirmation { 'ADMIN_PASSWORD' }
  end
end
```

### テストフィクスチャ

```
# spec/fixtures/files/test_image.jpg
# 実際の画像ファイルを配置
# サイズ: 100x100px程度の小さな画像
```

### JavaScript テスト（Jest）

```javascript
// spec/javascript/controllers/image_upload_controller.spec.js
import { Application } from "@hotwired/stimulus"
import ImageUploadController from "controllers/image_upload_controller"

describe("ImageUploadController", () => {
  let application
  let controller
  
  beforeEach(() => {
    application = Application.start()
    application.register("image-upload", ImageUploadController)
    
    document.body.innerHTML = `
      <div data-controller="image-upload">
        <input type="file" data-image-upload-target="fileInput" />
        <input type="text" data-image-upload-target="altText" />
        <input type="text" data-image-upload-target="caption" />
        <button data-action="click->image-upload#uploadAndInsert">アップロード</button>
      </div>
    `
    
    controller = application.getControllerForElementAndIdentifier(
      document.querySelector('[data-controller="image-upload"]'),
      "image-upload"
    )
  })
  
  afterEach(() => {
    application.stop()
  })
  
  describe("uploadAndInsert", () => {
    it("キャプション付きでアップロードする", async () => {
      // テスト実装
    })
    
    it("キャプションなしでアップロードする", async () => {
      // テスト実装
    })
  })
  
  describe("resetForm", () => {
    it("フォームをリセットする", () => {
      controller.altTextTarget.value = "テスト"
      controller.captionTarget.value = "キャプション"
      
      controller.resetForm()
      
      expect(controller.altTextTarget.value).toBe("")
      expect(controller.captionTarget.value).toBe("")
    })
  })
})
```

### カバレッジ目標

- Controller: 95%以上
- JavaScript: 90%以上

---

## 💡 実装メモ

### 実装対象ファイル

1. **ビュー**: `app/views/admin/articles/_form.html.erb`
   - キャプション入力フィールドの追加
   - Stimulus targetの追加: `data-image-upload-target="caption"`

2. **JavaScript**: `app/javascript/controllers/image_upload_controller.js`
   - `caption` targetの追加
   - `uploadAndInsert`メソッドでcaptionをFormDataに追加
   - `resetForm`メソッドでcaptionフィールドもクリア

3. **コントローラー**: `app/controllers/admin/article_images_controller.rb`
   - `params[:caption]`を受け取る
   - キャプションの有無で生成するコードを分岐
   - HTMLエスケープ処理（`ERB::Util.html_escape`）

4. **スタイルシート**: `app/assets/stylesheets/application.tailwind.css` または専用CSS
   - `.article-image` クラスのスタイリング
   - `figcaption` のスタイリング

### 実装例（コントローラー）

```ruby
def create
  @article = Article.find(params[:article_id])
  
  if params[:image].present?
    @article.content_images.attach(params[:image])
    image = @article.content_images.last
    
    if image.present?
      image_url = url_for(image)
      alt_text = params[:alt_text].presence || image.filename.to_s
      caption = params[:caption].presence
      
      # キャプションの有無で生成するコードを分岐
      markdown = if caption
        # HTMLエスケープ
        escaped_alt = ERB::Util.html_escape(alt_text)
        escaped_caption = ERB::Util.html_escape(caption)
        
        <<~HTML.strip
          <figure class="article-image">
            <img src="#{image_url}" alt="#{escaped_alt}" />
            <figcaption>#{escaped_caption}</figcaption>
          </figure>
        HTML
      else
        "![#{alt_text}](#{image_url})"
      end
      
      render json: {
        success: true,
        markdown: markdown,
        url: image_url,
        alt_text: alt_text,
        caption: caption,
        filename: image.filename.to_s
      }
    end
  end
end
```

### CSS実装例

```css
/* 記事内画像のスタイリング */
.article-image {
  margin: 2rem auto;
  text-align: center;
  max-width: 100%;
}

.article-image img {
  max-width: 100%;
  height: auto;
  border-radius: 0.5rem;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
}

.article-image figcaption {
  margin-top: 0.75rem;
  font-size: 0.875rem;
  color: #6b7280;
  font-style: italic;
  line-height: 1.5;
}

/* レスポンシブ対応 */
@media (max-width: 640px) {
  .article-image {
    margin: 1.5rem auto;
  }
  
  .article-image figcaption {
    font-size: 0.8125rem;
  }
}
```

### セキュリティ考慮事項
- キャプションテキストは必ず`ERB::Util.html_escape`でエスケープ
- alt属性も同様にエスケープ
- 画像URLは`url_for`で生成されるため安全

### 技術的制約
- Markdownパーサー（Redcarpet）はHTMLタグをそのまま通すため、`<figure>`タグは問題なく表示される
- 既存のMarkdown記法との互換性を保つため、キャプションなしの場合は従来通りの動作を維持

---

## 📊 実装履歴

| 日付 | 担当 | 内容 |
|------|------|------|
| 2024-12-26 | Kiro | 初版作成（Phase5実装待ち） |
| 2025-12-26 | Claude Code | 実装完了（Phase4.2） |

---

## 🔗 関連ドキュメント

- Phase計画書: `/docs/development/phase_plan_rails_8_1_1.md`
- 総合仕様書: `/docs/specifications/spec.md`
- 既存実装: `app/javascript/controllers/image_upload_controller.js`
- 既存実装: `app/controllers/admin/article_images_controller.rb`

---

## 📝 補足

### alt属性とfigcaptionの使い分け

- **alt属性**: 画像が表示されない場合の代替テキスト（スクリーンリーダー、画像読み込み失敗時）
  - 簡潔に画像の内容を説明
  - SEO対策として重要
  
- **figcaption**: 画像の補足説明やキャプション
  - 視覚的に表示される説明文
  - より詳細な情報や文脈を提供
  - 画像の出典、撮影情報なども記載可能

### 実装優先度
Phase4での実装を予定。Phase4.1（基本画像アップロード）完了後に着手する。
