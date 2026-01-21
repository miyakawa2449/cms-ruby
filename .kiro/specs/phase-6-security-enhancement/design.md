# Phase 6: セキュリティ強化 - 設計書

**Phase**: 6  
**作成日**: 2026-01-22  
**ステータス**: 設計完了  
**優先度**: 高  
**担当**: Codex（テスト・検証）

---

## 📋 設計概要

Phase 6 では、既存のセキュリティ機能を拡張し、より堅牢なセキュリティ体制を構築します。主に以下の3つの領域に焦点を当てます：

1. **セキュリティヘッダーの最適化**
2. **監視・ログ機能の強化**
3. **セキュリティテストの充実**

---

## 🏗️ アーキテクチャ

### システム構成

```
┌─────────────────────────────────────────────────────────┐
│                     ユーザー                              │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│                  Rack Middleware                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ Rack::Attack │  │ SecureHeaders│  │ CSRF Token   │  │
│  │ (Rate Limit) │  │ (Headers)    │  │ (Rails)      │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│                  Rails Application                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ Devise Auth  │  │ Security Log │  │ Input Valid  │  │
│  │ (認証)       │  │ (監視)       │  │ (検証)       │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│                  PostgreSQL Database                     │
└─────────────────────────────────────────────────────────┘
```

---

## 🔧 詳細設計

### 1. セキュリティヘッダー強化

#### 1.1 Content Security Policy (CSP)

**ファイル**: `config/initializers/content_security_policy.rb`

```ruby
# 本番環境用の厳格な CSP
Rails.application.config.content_security_policy do |policy|
  policy.default_src :self, :https
  policy.font_src    :self, :https, :data
  policy.img_src     :self, :https, :data, :blob
  policy.object_src  :none
  policy.script_src  :self, :https
  policy.style_src   :self, :https
  
  # 外部サービス（本番環境のみ）
  if Rails.env.production?
    # Google Analytics
    policy.script_src :self, :https, "https://www.googletagmanager.com"
    policy.img_src :self, :https, :data, "https://www.google-analytics.com"
    
    # SNS 埋め込み
    policy.frame_src "https://www.youtube.com", "https://twitter.com", "https://platform.twitter.com"
  end
  
  # 開発環境用の緩和設定
  if Rails.env.development?
    policy.script_src :self, :https, :unsafe_eval, :unsafe_inline
    policy.style_src  :self, :https, :unsafe_inline
  end
end

# CSP 違反レポート（本番環境のみ）
if Rails.env.production?
  Rails.application.config.content_security_policy_report_only = false
  Rails.application.config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  Rails.application.config.content_security_policy_nonce_directives = %w[script-src]
end
```

#### 1.2 その他のセキュリティヘッダー

**ファイル**: `config/initializers/security_headers.rb`（新規作成）

```ruby
# セキュリティヘッダーの設定
Rails.application.config.action_dispatch.default_headers.merge!(
  # XSS 対策
  'X-Content-Type-Options' => 'nosniff',
  'X-XSS-Protection' => '1; mode=block',
  
  # クリックジャッキング対策
  'X-Frame-Options' => 'SAMEORIGIN',
  
  # Referrer 制御
  'Referrer-Policy' => 'strict-origin-when-cross-origin',
  
  # Permissions Policy
  'Permissions-Policy' => 'geolocation=(), microphone=(), camera=()'
)

# HSTS（本番環境のみ）
if Rails.env.production?
  Rails.application.config.force_ssl = true
  Rails.application.config.ssl_options = {
    hsts: {
      expires: 1.year.to_i,
      subdomains: true,
      preload: true
    }
  }
end
```

---

### 2. 監視・ログ機能強化

#### 2.1 セキュリティイベントログ

**ファイル**: `app/services/security_logger.rb`（新規作成）

```ruby
# セキュリティイベントのログ記録サービス
class SecurityLogger
  class << self
    # ログイン成功
    def log_login_success(user, request)
      log_event(
        event: 'login_success',
        user_id: user.id,
        email: user.email,
        ip: request.remote_ip,
        user_agent: request.user_agent
      )
    end
    
    # ログイン失敗
    def log_login_failure(email, request, reason: 'invalid_credentials')
      log_event(
        event: 'login_failure',
        email: email,
        reason: reason,
        ip: request.remote_ip,
        user_agent: request.user_agent
      )
    end
    
    # ログアウト
    def log_logout(user, request)
      log_event(
        event: 'logout',
        user_id: user.id,
        email: user.email,
        ip: request.remote_ip
      )
    end
    
    # アカウントロック
    def log_account_locked(user, request)
      log_event(
        event: 'account_locked',
        user_id: user.id,
        email: user.email,
        ip: request.remote_ip,
        severity: 'warning'
      )
    end
    
    # アカウントアンロック
    def log_account_unlocked(user)
      log_event(
        event: 'account_unlocked',
        user_id: user.id,
        email: user.email,
        severity: 'info'
      )
    end
    
    # 不正アクセス試行
    def log_unauthorized_access(path, request)
      log_event(
        event: 'unauthorized_access',
        path: path,
        ip: request.remote_ip,
        user_agent: request.user_agent,
        severity: 'warning'
      )
    end
    
    # Rack::Attack ブロック
    def log_rate_limit_exceeded(discriminator, request)
      log_event(
        event: 'rate_limit_exceeded',
        discriminator: discriminator,
        ip: request.remote_ip,
        path: request.path,
        severity: 'warning'
      )
    end
    
    private
    
    def log_event(event_data)
      severity = event_data.delete(:severity) || 'info'
      
      log_data = {
        timestamp: Time.current.iso8601,
        environment: Rails.env,
        **event_data
      }
      
      case severity
      when 'warning'
        Rails.logger.warn("[SECURITY] #{log_data.to_json}")
      when 'error'
        Rails.logger.error("[SECURITY] #{log_data.to_json}")
      else
        Rails.logger.info("[SECURITY] #{log_data.to_json}")
      end
    end
  end
end
```

#### 2.2 Devise コールバック

**ファイル**: `app/models/admin_user.rb`（既存ファイルに追加）

```ruby
class AdminUser < ApplicationRecord
  devise :database_authenticatable, :recoverable, :rememberable, 
         :validatable, :trackable, :lockable, :timeoutable
  
  # Devise コールバック
  after_sign_in do |user, opts|
    SecurityLogger.log_login_success(user, opts[:request]) if opts[:request]
  end
  
  after_failed_sign_in do |user, opts|
    email = user.try(:email) || opts[:email]
    SecurityLogger.log_login_failure(email, opts[:request]) if opts[:request]
  end
  
  after_lock do |user, opts|
    SecurityLogger.log_account_locked(user, opts[:request]) if opts[:request]
  end
  
  after_unlock do |user, opts|
    SecurityLogger.log_account_unlocked(user)
  end
end
```

#### 2.3 Rack::Attack ログ

**ファイル**: `config/initializers/rack_attack.rb`（既存ファイルに追加）

```ruby
# Rack::Attack のイベント通知
ActiveSupport::Notifications.subscribe('rack.attack') do |name, start, finish, request_id, payload|
  request = payload[:request]
  
  if request.env['rack.attack.matched']
    SecurityLogger.log_rate_limit_exceeded(
      request.env['rack.attack.matched'],
      request
    )
  end
end
```

---

### 3. Rack::Attack 設定の最適化

#### 3.1 レート制限の調整

**ファイル**: `config/initializers/rack_attack.rb`（既存ファイルを更新）

```ruby
class Rack::Attack
  # Redis を使用（本番環境）
  if Rails.env.production?
    Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(
      url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/1')
    )
  else
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
  end
  
  # ホワイトリスト（管理者IP）
  safelist('allow from admin IPs') do |req|
    admin_ips = ENV.fetch('ADMIN_WHITELIST_IPS', '').split(',')
    admin_ips.include?(req.ip) if admin_ips.any?
  end
  
  # ログイン試行制限（既存を維持）
  throttle("logins/ip", limit: 5, period: 20.seconds) do |req|
    if req.path.end_with?("/sign_in") && req.post?
      req.ip
    end
  end
  
  # API レート制限（認証済み vs 未認証）
  throttle("api/authenticated", limit: 300, period: 1.minute) do |req|
    if req.path.start_with?("/api") && req.env['warden'].user
      req.env['warden'].user.id
    end
  end
  
  throttle("api/unauthenticated", limit: 60, period: 1.minute) do |req|
    if req.path.start_with?("/api") && !req.env['warden'].user
      req.ip
    end
  end
  
  # 管理画面への不正アクセス試行
  throttle("admin/ip", limit: 10, period: 1.minute) do |req|
    admin_path = ENV.fetch('ADMIN_PATH', 'admin')
    if req.path.start_with?("/#{admin_path}") && !req.env['warden'].user
      req.ip
    end
  end
end
```

---

### 4. 入力検証・サニタイゼーション

#### 4.1 Markdown サニタイゼーション

**ファイル**: `app/helpers/markdown_helper.rb`（既存ファイルを確認）

```ruby
module MarkdownHelper
  def markdown(text)
    return '' if text.blank?
    
    # Redcarpet の安全な設定
    renderer = Redcarpet::Render::HTML.new(
      filter_html: false,  # HTML タグを許可（サニタイズは後で実行）
      no_images: false,
      no_links: false,
      hard_wrap: true,
      link_attributes: { target: '_blank', rel: 'noopener noreferrer' }
    )
    
    markdown = Redcarpet::Markdown.new(renderer,
      autolink: true,
      tables: true,
      fenced_code_blocks: true,
      strikethrough: true,
      superscript: true
    )
    
    # HTML をサニタイズ
    sanitize(markdown.render(text), tags: allowed_tags, attributes: allowed_attributes)
  end
  
  private
  
  def allowed_tags
    %w[
      h1 h2 h3 h4 h5 h6 p br hr
      strong em u s del ins mark
      ul ol li
      blockquote pre code
      a img
      table thead tbody tr th td
    ]
  end
  
  def allowed_attributes
    {
      'a' => ['href', 'title', 'target', 'rel'],
      'img' => ['src', 'alt', 'title', 'width', 'height'],
      'code' => ['class'],
      'pre' => ['class']
    }
  end
end
```

#### 4.2 ファイルアップロード検証

**ファイル**: `app/models/concerns/media_validatable.rb`（新規作成）

```ruby
# メディアファイルのバリデーション
module MediaValidatable
  extend ActiveSupport::Concern
  
  ALLOWED_IMAGE_TYPES = %w[image/jpeg image/png image/gif image/webp].freeze
  MAX_FILE_SIZE = 10.megabytes
  
  included do
    validate :validate_image_content_type
    validate :validate_image_file_size
  end
  
  private
  
  def validate_image_content_type
    return unless image.attached?
    
    unless ALLOWED_IMAGE_TYPES.include?(image.content_type)
      errors.add(:image, "は JPEG、PNG、GIF、WebP 形式のみアップロード可能です")
    end
    
    # MIME タイプと実際のファイル内容の一致を確認
    unless image.blob.content_type == Marcel::MimeType.for(image.blob.download)
      errors.add(:image, "のファイル形式が不正です")
    end
  end
  
  def validate_image_file_size
    return unless image.attached?
    
    if image.blob.byte_size > MAX_FILE_SIZE
      errors.add(:image, "のサイズは #{MAX_FILE_SIZE / 1.megabyte}MB 以下にしてください")
    end
  end
end
```

---

### 5. セキュリティテスト

#### 5.1 テスト構成

```
spec/
├── security/
│   ├── headers_spec.rb           # セキュリティヘッダーのテスト
│   ├── authentication_spec.rb    # 認証のテスト
│   ├── rate_limiting_spec.rb     # レート制限のテスト
│   ├── input_validation_spec.rb  # 入力検証のテスト
│   ├── csrf_spec.rb              # CSRF 対策のテスト
│   └── session_spec.rb           # セッション管理のテスト
└── services/
    └── security_logger_spec.rb   # SecurityLogger のテスト
```

#### 5.2 テスト例

**ファイル**: `spec/security/headers_spec.rb`（新規作成）

```ruby
require 'rails_helper'

RSpec.describe 'Security Headers', type: :request do
  describe 'Content Security Policy' do
    it 'sets CSP header' do
      get root_path
      expect(response.headers['Content-Security-Policy']).to be_present
    end
    
    it 'includes default-src directive' do
      get root_path
      csp = response.headers['Content-Security-Policy']
      expect(csp).to include('default-src')
    end
  end
  
  describe 'X-Frame-Options' do
    it 'sets X-Frame-Options header' do
      get root_path
      expect(response.headers['X-Frame-Options']).to eq('SAMEORIGIN')
    end
  end
  
  describe 'X-Content-Type-Options' do
    it 'sets X-Content-Type-Options header' do
      get root_path
      expect(response.headers['X-Content-Type-Options']).to eq('nosniff')
    end
  end
  
  describe 'Referrer-Policy' do
    it 'sets Referrer-Policy header' do
      get root_path
      expect(response.headers['Referrer-Policy']).to eq('strict-origin-when-cross-origin')
    end
  end
  
  describe 'Permissions-Policy' do
    it 'sets Permissions-Policy header' do
      get root_path
      expect(response.headers['Permissions-Policy']).to be_present
    end
  end
end
```

---

## 📊 データモデル

### 既存モデルの拡張

#### AdminUser モデル

```ruby
# 既存のカラム
- email: string
- encrypted_password: string
- reset_password_token: string
- reset_password_sent_at: datetime
- remember_created_at: datetime
- sign_in_count: integer
- current_sign_in_at: datetime
- last_sign_in_at: datetime
- current_sign_in_ip: string
- last_sign_in_ip: string
- failed_attempts: integer
- unlock_token: string
- locked_at: datetime

# 新規カラム（不要、既存で十分）
```

---

## 🔄 処理フロー

### ログイン処理フロー

```
1. ユーザーがログインフォームを送信
   ↓
2. Rack::Attack がレート制限をチェック
   ├─ 制限超過 → 429 エラー + ログ記録
   └─ OK → 次へ
   ↓
3. Devise が認証処理
   ├─ 成功 → SecurityLogger.log_login_success
   └─ 失敗 → SecurityLogger.log_login_failure
   ↓
4. アカウントロック判定（5回失敗）
   ├─ ロック → SecurityLogger.log_account_locked
   └─ OK → 次へ
   ↓
5. セッション作成 + セキュリティヘッダー付与
   ↓
6. 管理画面へリダイレクト
```

### API リクエスト処理フロー

```
1. API リクエスト受信
   ↓
2. Rack::Attack がレート制限をチェック
   ├─ 認証済み → 300回/分
   └─ 未認証 → 60回/分
   ↓
3. 制限超過判定
   ├─ 超過 → 429 エラー + Retry-After ヘッダー
   └─ OK → 次へ
   ↓
4. コントローラー処理
   ↓
5. レスポンス返却 + セキュリティヘッダー
```

---

## 🎯 正確性プロパティ

### Property 1: セキュリティヘッダーの存在

**検証要件**: US-6.1（セキュリティヘッダー強化）

**プロパティ**: すべてのHTTPレスポンスに必須のセキュリティヘッダーが含まれる

```ruby
# spec/security/headers_spec.rb
property 'all responses include required security headers' do
  paths = [root_path, blog_path, admin_root_path]
  
  paths.each do |path|
    get path
    
    expect(response.headers['X-Frame-Options']).to eq('SAMEORIGIN')
    expect(response.headers['X-Content-Type-Options']).to eq('nosniff')
    expect(response.headers['Referrer-Policy']).to be_present
  end
end
```

### Property 2: レート制限の一貫性

**検証要件**: US-6.4（APIセキュリティ強化）

**プロパティ**: レート制限を超えるリクエストは必ず429エラーを返す

```ruby
# spec/security/rate_limiting_spec.rb
property 'rate limiting consistently blocks excessive requests' do
  6.times do
    post admin_user_session_path, params: { 
      admin_user: { email: 'test@example.com', password: 'wrong' }
    }
  end
  
  expect(response.status).to eq(429)
  expect(response.headers['Retry-After']).to be_present
end
```

### Property 3: ログ記録の完全性

**検証要件**: US-6.3（セキュリティ監視・ログ機能）

**プロパティ**: すべてのセキュリティイベントがログに記録される

```ruby
# spec/services/security_logger_spec.rb
property 'all security events are logged' do
  expect(Rails.logger).to receive(:info).with(/\[SECURITY\]/)
  
  SecurityLogger.log_login_success(user, request)
end
```

---

## 🚀 デプロイ計画

### ステップ1: 開発環境でのテスト

1. セキュリティヘッダーの設定
2. SecurityLogger の実装
3. テストの作成・実行
4. カバレッジ確認（90%以上）

### ステップ2: ステージング環境でのテスト

1. 本番環境と同じ設定でテスト
2. パフォーマンステスト
3. セキュリティスキャン

### ステップ3: 本番環境へのデプロイ

1. メンテナンスモード有効化
2. 設定ファイルのデプロイ
3. アプリケーションの再起動
4. 動作確認
5. メンテナンスモード解除

### ロールバック手順

1. 旧バージョンの設定ファイルに戻す
2. アプリケーションの再起動
3. 動作確認

---

## 📝 注意事項

### セキュリティ上の注意

1. **環境変数の管理**: 本番環境の環境変数は `.env.production` で管理（gitignore対象）
2. **ログの保護**: セキュリティログには個人情報が含まれるため、適切に保護
3. **段階的な導入**: セキュリティ設定は段階的に導入し、影響を監視

### パフォーマンス上の注意

1. **Redis の使用**: 本番環境では Rack::Attack のキャッシュに Redis を使用
2. **ログの最適化**: ログ記録による処理時間への影響を最小化
3. **ヘッダーサイズ**: CSP ヘッダーが大きくなりすぎないよう注意

---

**設計者**: Kiro（仕様管理担当）  
**設計日**: 2026-01-22  
**承認日**: 2026-01-22  
**次のステップ**: タスクリスト作成 → Codex への依頼
