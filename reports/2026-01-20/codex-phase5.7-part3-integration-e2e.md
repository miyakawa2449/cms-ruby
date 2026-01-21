# Phase 5.7 テストカバレッジ向上 - Part 3: 統合テスト・E2Eテスト

---

## ✅ Task 5: 統合テスト - 記事CRUD（20件）

### ファイル: `spec/requests/admin/articles_crud_spec.rb`

### 作成フロー（5件）

```ruby
describe '記事作成フロー' do
  let(:admin_user) { create(:admin_user) }
  
  before { sign_in admin_user }

  it '記事作成ページが表示される' do
    get new_admin_article_path
    expect(response).to have_http_status(:success)
  end

  it 'AI機能でタイトル提案ができる' do
    article = create(:article, :draft, admin_user: admin_user)
    
    post suggest_title_admin_article_path(article), 
         params: { content: "Sample content" }
    
    expect(response).to have_http_status(:success)
    expect(JSON.parse(response.body)['titles']).to be_present
  end

  it '記事を保存できる' do
    expect {
      post admin_articles_path, params: {
        article: attributes_for(:article, :draft)
      }
    }.to change(Article, :count).by(1)
  end

  it '保存後に記事詳細ページにリダイレクトされる' do
    post admin_articles_path, params: {
      article: attributes_for(:article, :draft)
    }
    
    expect(response).to redirect_to(admin_article_path(Article.last))
  end

  it 'バリデーションエラー時にエラーメッセージが表示される' do
    post admin_articles_path, params: {
      article: { title: '' }
    }
    
    expect(response).to have_http_status(:unprocessable_entity)
  end
end
```

### 編集フロー（5件）
- 記事編集ページ表示
- カテゴリ変更
- タグ変更
- 画像アップロード
- 更新確認

### 削除フロー（5件）
- 記事削除
- キャッシュ無効化確認
- 関連データ削除確認
- Active Storage削除確認
- リダイレクト確認

### 公開フロー（5件）
- 下書き保存
- 公開
- フロントエンド表示確認
- 非公開
- アクセス拒否確認

---

## ✅ Task 6: 統合テスト - 認証・認可（15件）

### ファイル: `spec/requests/admin/authentication_spec.rb`

### ログイン・ログアウト（5件）

```ruby
describe '認証フロー' do
  let(:admin_user) { create(:admin_user) }

  it '正常にログインできる' do
    post admin_user_session_path, params: {
      admin_user: {
        email: admin_user.email,
        password: admin_user.password
      }
    }
    
    expect(response).to redirect_to(admin_dashboard_path)
  end

  it '不正な認証情報でログインできない' do
    post admin_user_session_path, params: {
      admin_user: {
        email: admin_user.email,
        password: 'wrong_password'
      }
    }
    
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it 'ログアウトできる' do
    sign_in admin_user
    
    delete destroy_admin_user_session_path
    
    expect(response).to redirect_to(root_path)
  end

  it 'セッションが維持される' do
    sign_in admin_user
    
    get admin_dashboard_path
    
    expect(response).to have_http_status(:success)
  end

  it 'Remember me機能が動作する' do
    post admin_user_session_path, params: {
      admin_user: {
        email: admin_user.email,
        password: admin_user.password,
        remember_me: '1'
      }
    }
    
    expect(response.cookies['remember_admin_user_token']).to be_present
  end
end
```

### アクセス拒否（5件）
- 非認証ユーザーのアクセス拒否
- 管理画面へのアクセス拒否
- API認証エラー
- CSRF保護
- XSS保護

### セッション管理（5件）
- セッション作成
- セッション更新
- セッション削除
- セッションタイムアウト
- 同時ログイン制御

---

## ✅ Task 7: 統合テスト - APIエンドポイント（25件）

### 記事API（10件）

**ファイル**: `spec/requests/api/v1/articles_spec.rb`

```ruby
RSpec.describe 'Api::V1::Articles', type: :request do
  describe 'GET /api/v1/articles' do
    it '記事一覧を取得できる' do
      create_list(:article, 3, :published)
      
      get api_v1_articles_path
      
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body).size).to eq(3)
    end

    it 'ページネーションが機能する' do
      create_list(:article, 15, :published)
      
      get api_v1_articles_path, params: { page: 2, per_page: 10 }
      
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body).size).to eq(5)
    end
  end

  describe 'GET /api/v1/articles/:id' do
    it '記事詳細を取得できる' do
      article = create(:article, :published)
      
      get api_v1_article_path(article)
      
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)['id']).to eq(article.id)
    end
  end

  # 残り7件のテストを実装...
end
```

### カテゴリAPI（5件）
- GET /api/v1/categories
- GET /api/v1/categories/:id
- POST /api/v1/categories
- PATCH /api/v1/categories/:id
- DELETE /api/v1/categories/:id

### タグAPI（5件）
- GET /api/v1/tags
- GET /api/v1/tags/:id
- POST /api/v1/tags
- PATCH /api/v1/tags/:id
- DELETE /api/v1/tags/:id

### AI API（5件）
- POST /api/v1/ai/suggest_title
- POST /api/v1/ai/generate_summary
- POST /api/v1/ai/suggest_tags
- POST /api/v1/ai/generate_slug
- POST /api/v1/ai/generate_seo_meta

---

## ✅ Task 8-9: E2Eテスト（15件）

### 記事作成フローE2Eテスト（10件）

**ファイル**: `spec/system/article_creation_spec.rb`

```ruby
require 'rails_helper'

RSpec.describe '記事作成フロー', type: :system do
  let(:admin_user) { create(:admin_user) }

  before do
    driven_by(:selenium_headless)
    login_as(admin_user, scope: :admin_user)
  end

  it 'ログインから記事作成まで完了できる' do
    visit new_admin_article_path

    fill_in 'タイトル', with: 'テスト記事'
    fill_in '本文', with: 'テスト本文'
    
    click_button '保存'

    expect(page).to have_content('記事を作成しました')
    expect(page).to have_content('テスト記事')
  end

  it 'タイトル提案ボタンをクリックして提案を受け取れる' do
    visit new_admin_article_path

    fill_in '本文', with: 'サンプルコンテンツ'
    
    click_button 'タイトル提案'

    expect(page).to have_css('.loading-indicator')
    expect(page).to have_css('.title-suggestions', wait: 10)
  end

  it '提案されたタイトルを適用できる' do
    visit new_admin_article_path

    fill_in '本文', with: 'サンプルコンテンツ'
    click_button 'タイトル提案'

    within('.title-suggestions') do
      first('.suggestion-item').click
    end

    expect(find_field('タイトル').value).not_to be_empty
  end

  # 残り7件のテストを実装...
end
```

### 画像・メディアフローE2Eテスト（5件）

**ファイル**: `spec/system/media_upload_spec.rb`

```ruby
RSpec.describe '画像アップロードフロー', type: :system do
  let(:admin_user) { create(:admin_user) }

  before do
    driven_by(:selenium_headless)
    login_as(admin_user, scope: :admin_user)
  end

  it '画像をアップロードできる' do
    visit new_admin_article_path

    attach_file '画像', Rails.root.join('spec/fixtures/files/test_image.jpg')
    
    click_button 'アップロード'

    expect(page).to have_css('img[src*="test_image"]')
  end

  # 残り4件のテストを実装...
end
```

---

次のファイル: Part 4 - 成果物・注意事項
