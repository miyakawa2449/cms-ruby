# Admin Test Helpers for Portfolio Site
# 管理画面テスト用のヘルパーメソッド集

module AdminTestHelpers
  # ==> Authentication Helpers
  
  def sign_in_admin(admin_user = nil)
    # 管理者としてログイン（Phase 2Bで実装予定）
    admin = admin_user || create_test_admin
    # sign_in admin, scope: :admin_user
    @current_admin_user = admin
    session[:admin_user_id] = admin.id if defined?(session)
    admin
  end
  
  def sign_out_admin
    # 管理者ログアウト
    # sign_out :admin_user
    @current_admin_user = nil
    session.delete(:admin_user_id) if defined?(session)
  end
  
  def create_test_admin(attributes = {})
    # テスト用管理者アカウント作成
    default_attributes = {
      email: 'admin@test.example.com',
      password: 'TestPassword123!',
      password_confirmation: 'TestPassword123!',
      name: 'Test Admin',
      role: 'admin',
      status: 'active',
      confirmed_at: Time.current
    }
    
    # AdminUser.create!(default_attributes.merge(attributes))
    # Phase 2A用のモック（実際のモデル作成は Phase 2B で実装）
    OpenStruct.new(default_attributes.merge(attributes).merge(id: 1, persisted?: true))
  end
  
  def create_super_admin(attributes = {})
    create_test_admin(attributes.merge(role: 'super_admin'))
  end
  
  def create_editor(attributes = {})
    create_test_admin(attributes.merge(role: 'editor'))
  end
  
  def create_viewer(attributes = {})
    create_test_admin(attributes.merge(role: 'viewer'))
  end
  
  # ==> Authorization Helpers
  
  def expect_admin_access_denied
    # 管理画面アクセス拒否の期待
    expect(response).to have_http_status(:redirect)
    expect(response).to redirect_to(admin_new_admin_user_session_path)
  end
  
  def expect_admin_forbidden
    # 権限不足での403エラーの期待
    expect(response).to have_http_status(:forbidden)
  end
  
  def expect_admin_success
    # 管理画面正常アクセスの期待
    expect(response).to have_http_status(:success)
  end
  
  # ==> Request Helpers
  
  def admin_get(path, **options)
    # 管理者としてGETリクエスト
    get(path, **options)
  end
  
  def admin_post(path, **options)
    # 管理者としてPOSTリクエスト
    post(path, **options)
  end
  
  def admin_patch(path, **options)
    # 管理者としてPATCHリクエスト
    patch(path, **options)
  end
  
  def admin_delete(path, **options)
    # 管理者としてDELETEリクエスト
    delete(path, **options)
  end
  
  # ==> Form Helpers
  
  def fill_in_admin_login_form(email: 'admin@test.example.com', password: 'TestPassword123!')
    # 管理者ログインフォーム入力（Capybara用）
    fill_in 'Email', with: email
    fill_in 'Password', with: password
  end
  
  def submit_admin_login_form
    # 管理者ログインフォーム送信
    click_button 'ログイン'
  end
  
  def fill_in_admin_user_form(attributes = {})
    # 管理者ユーザー作成/編集フォーム入力
    default_attributes = {
      name: 'Test User',
      email: 'test@example.com',
      role: 'editor',
      status: 'active'
    }
    
    attrs = default_attributes.merge(attributes)
    
    fill_in 'Name', with: attrs[:name]
    fill_in 'Email', with: attrs[:email]
    select attrs[:role].humanize, from: 'Role'
    select attrs[:status].humanize, from: 'Status'
  end
  
  # ==> Data Helpers
  
  def create_test_article(attributes = {})
    # テスト用記事作成
    default_attributes = {
      title: 'Test Article',
      content: 'This is a test article content.',
      status: 'published',
      admin_user: @current_admin_user || create_test_admin
    }
    
    # Article.create!(default_attributes.merge(attributes))
    # Phase 2A用のモック
    OpenStruct.new(default_attributes.merge(attributes).merge(id: 1))
  end
  
  def create_test_category(attributes = {})
    # テスト用カテゴリ作成
    default_attributes = {
      name: 'Test Category',
      slug: 'test-category',
      description: 'Test category description',
      visible: true
    }
    
    # Category.create!(default_attributes.merge(attributes))
    # Phase 2A用のモック
    OpenStruct.new(default_attributes.merge(attributes).merge(id: 1))
  end
  
  def create_test_tag(attributes = {})
    # テスト用タグ作成
    default_attributes = {
      name: 'Test Tag',
      slug: 'test-tag',
      description: 'Test tag description',
      visible: true
    }
    
    # Tag.create!(default_attributes.merge(attributes))
    # Phase 2A用のモック
    OpenStruct.new(default_attributes.merge(attributes).merge(id: 1))
  end
  
  # ==> Session Helpers
  
  def admin_session_data
    # 管理者セッションデータの取得
    {
      admin_user_id: @current_admin_user&.id,
      admin_login_time: Time.current,
      admin_ip_address: '127.0.0.1',
      admin_user_agent: 'Test User Agent'
    }
  end
  
  def setup_admin_session
    # 管理者セッション設定
    session.merge!(admin_session_data) if defined?(session)
  end
  
  def clear_admin_session
    # 管理者セッションクリア
    %i[admin_user_id admin_login_time admin_ip_address admin_user_agent].each do |key|
      session.delete(key) if defined?(session)
    end
  end
  
  # ==> Security Helpers
  
  def expect_csrf_protection
    # CSRF保護の確認
    expect(controller).to be_protect_from_forgery if defined?(controller)
  end
  
  def expect_authentication_required
    # 認証が必要な画面の確認
    expect(response).to have_http_status(:redirect)
    follow_redirect!
    expect(request.path).to eq(admin_new_admin_user_session_path)
  end
  
  def with_admin_path(custom_path)
    # カスタム管理パスでのテスト実行
    original_path = ENV['ADMIN_PATH']
    ENV['ADMIN_PATH'] = custom_path
    yield
  ensure
    ENV['ADMIN_PATH'] = original_path
  end
  
  # ==> Utility Helpers
  
  def admin_path_prefix
    # 管理パスのプレフィックス取得
    ENV['ADMIN_PATH'] || 'admin'
  end
  
  def expect_admin_flash_message(type, message = nil)
    # Flash メッセージの確認
    expect(flash[type]).to be_present
    expect(flash[type]).to include(message) if message
  end
  
  def expect_admin_breadcrumbs(*expected_crumbs)
    # パンくずリストの確認
    expect(assigns(:admin_breadcrumbs)).to be_present
    
    expected_crumbs.each_with_index do |crumb, index|
      expect(assigns(:admin_breadcrumbs)[index][:title]).to eq(crumb)
    end
  end
  
  def expect_admin_page_title(title)
    # ページタイトルの確認
    expect(assigns(:page_title)).to eq(title)
  end
  
  def mock_admin_notifications(count = 3)
    # 管理者通知のモック作成
    Array.new(count) do |i|
      {
        id: i + 1,
        title: "Test Notification #{i + 1}",
        message: "This is test notification #{i + 1}",
        type: %w[info warning error].sample,
        created_at: i.hours.ago,
        read: false
      }
    end
  end
  
  def mock_admin_stats
    # 管理ダッシュボード統計のモック
    {
      articles_count: 25,
      published_articles: 20,
      draft_articles: 5,
      comments_pending: 3,
      media_files_count: 150,
      total_views: 5420,
      monthly_views: 1250
    }
  end
end