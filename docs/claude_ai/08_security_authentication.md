# セキュリティ＆認証仕様書

## セキュリティ概要

### セキュリティ方針
1. **多層防御**: 複数の防御レイヤーによる包括的保護
2. **最小権限原則**: 必要最小限の権限のみ付与
3. **セキュア・バイ・デザイン**: 設計段階からのセキュリティ考慮
4. **継続的監視**: リアルタイムでの脅威検出と対応

### 脅威モデル
- **外部攻撃**: SQLインジェクション、XSS、CSRF
- **認証攻撃**: ブルートフォース、セッションハイジャック
- **データ漏洩**: 不正アクセス、権限昇格
- **DoS攻撃**: レート制限、リソース枯渇

## 認証システム

### 管理画面認証（Devise）

#### 基本設定
```ruby
# config/initializers/devise.rb
Devise.setup do |config|
  # セッションキー暗号化
  config.secret_key = Rails.application.credentials.devise_secret_key
  
  # パスワード要件
  config.password_length = 8..128
  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/
  
  # セッション管理
  config.timeout_in = 30.minutes
  config.expire_all_remember_me_on_sign_out = true
  
  # ロック機能
  config.lock_strategy = :failed_attempts
  config.unlock_keys = [:email]
  config.unlock_strategy = :email
  config.maximum_attempts = 5
  config.unlock_in = 1.hour
  
  # 確認機能（本番のみ）
  config.confirm_within = 3.days
  config.confirmation_keys = [:email]
  
  # トラッキング
  config.sign_in_after_reset_password = false
end
```

#### AdminUserモデルのセキュリティ機能
```ruby
class AdminUser < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :timeoutable, :trackable
  
  # パスワード複雑性検証
  validates :password, 
    format: { 
      with: /\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/,
      message: "パスワードは大文字、小文字、数字、特殊文字を含む必要があります"
    },
    if: :password_required?
  
  # 2段階認証（将来実装）
  # has_one_time_password(encrypted: true)
  
  # セキュリティイベントログ
  has_many :security_events, dependent: :destroy
  
  # IP制限（オプション）
  def allowed_ip?(ip)
    return true if allowed_ips.empty?
    allowed_ips.include?(ip)
  end
  
  # 最終アクセス時刻の記録
  def update_last_activity
    update_column(:last_activity_at, Time.current)
  end
end
```

### API認証（JWT）

#### JWT設定
```ruby
# app/lib/jwt_service.rb
class JwtService
  SECRET_KEY = Rails.application.credentials.jwt_secret_key
  ALGORITHM = 'HS256'
  
  class << self
    def encode(payload, exp = 24.hours.from_now)
      payload[:exp] = exp.to_i
      payload[:iat] = Time.current.to_i
      payload[:jti] = SecureRandom.uuid # JWT ID for revocation
      
      JWT.encode(payload, SECRET_KEY, ALGORITHM)
    end
    
    def decode(token)
      decoded = JWT.decode(token, SECRET_KEY, true, { algorithm: ALGORITHM })
      HashWithIndifferentAccess.new(decoded[0])
    rescue JWT::DecodeError => e
      raise AuthenticationError, "無効なトークンです: #{e.message}"
    end
    
    def revoked?(jti)
      Rails.cache.read("revoked_token:#{jti}").present?
    end
    
    def revoke(jti, exp)
      Rails.cache.write("revoked_token:#{jti}", true, expires_in: exp)
    end
  end
end
```

#### API認証コントローラー
```ruby
class Api::V1::BaseController < ActionController::API
  include ActionController::HttpAuthentication::Token::ControllerMethods
  
  before_action :authenticate_api_user!, except: [:index, :show]
  
  private
  
  def authenticate_api_user!
    authenticate_with_http_token do |token, options|
      begin
        @decoded_token = JwtService.decode(token)
        @current_api_user = AdminUser.find(@decoded_token[:user_id])
        
        # トークン無効化チェック
        if JwtService.revoked?(@decoded_token[:jti])
          render_error('トークンが無効化されています', :unauthorized)
          return false
        end
        
        # アクティビティ更新
        @current_api_user.update_last_activity
        true
      rescue ActiveRecord::RecordNotFound
        render_error('ユーザーが見つかりません', :unauthorized)
        false
      rescue AuthenticationError => e
        render_error(e.message, :unauthorized)
        false
      end
    end
  end
  
  def current_api_user
    @current_api_user
  end
end
```

### セッション管理

#### セッション設定
```ruby
# config/application.rb
config.session_store :redis_session_store,
  key: '_portfolio_session',
  redis: {
    host: ENV.fetch('REDIS_HOST', 'localhost'),
    port: ENV.fetch('REDIS_PORT', 6379),
    db: ENV.fetch('REDIS_SESSION_DB', 1),
    password: ENV.fetch('REDIS_PASSWORD', nil)
  },
  expire_after: 1.hour,
  secure: Rails.env.production?,
  httponly: true,
  same_site: :lax
```

#### CSRFプロテクション
```ruby
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  
  # API用のCSRF例外
  skip_before_action :verify_authenticity_token, if: :api_request?
  
  private
  
  def api_request?
    request.path.start_with?('/api/')
  end
end
```

## セキュリティ対策

### 1. 入力検証・サニタイゼーション

#### Strong Parameters
```ruby
def article_params
  params.require(:article).permit(
    :title, :content, :excerpt, :status,
    category_ids: [], tag_ids: []
  ).tap do |whitelisted|
    # HTMLサニタイゼーション
    whitelisted[:content] = sanitize_html(whitelisted[:content])
    whitelisted[:excerpt] = sanitize_html(whitelisted[:excerpt])
  end
end

private

def sanitize_html(html)
  ActionController::Base.helpers.sanitize(html, 
    tags: %w[p br strong em h1 h2 h3 ul ol li blockquote code pre],
    attributes: %w[href src alt title]
  )
end
```

#### SQL インジェクション対策
```ruby
# 安全なクエリの例
class Article < ApplicationRecord
  scope :search_by_title, ->(query) do
    where("title ILIKE ?", "%#{sanitize_sql_like(query)}%")
  end
  
  # Parameterized queryの使用
  def self.find_by_complex_condition(title, status)
    where("title = ? AND status = ?", title, status)
  end
end
```

### 2. XSS対策

#### Content Security Policy
```ruby
# config/initializers/content_security_policy.rb
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self, :https
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data, 'blob:'
    policy.object_src  :none
    policy.script_src  :self, :https, :unsafe_inline
    policy.style_src   :self, :https, :unsafe_inline
    
    # 開発環境のみ
    if Rails.env.development?
      policy.connect_src :self, :https, 'ws://localhost:*'
    end
  end
  
  # 違反レポート
  config.content_security_policy_report_only = Rails.env.development?
  config.content_security_policy_nonce_generator = ->(request) { SecureRandom.base64(16) }
end
```

#### HTMLエスケープ
```erb
<!-- 自動エスケープ -->
<%= @article.title %>

<!-- 生HTMLの場合（注意深く使用） -->
<%== sanitize(@article.content_html) %>

<!-- JavaScriptデータの安全な埋め込み -->
<script>
  window.articleData = <%= @article.to_json.html_safe %>;
</script>
```

### 3. レート制限（Rack Attack）

#### 基本設定
```ruby
# config/initializers/rack_attack.rb
class Rack::Attack
  # Redis設定
  redis = Redis.new(
    host: ENV.fetch('REDIS_HOST', 'localhost'),
    port: ENV.fetch('REDIS_PORT', 6379),
    db: ENV.fetch('REDIS_ATTACK_DB', 2)
  )
  
  Rack::Attack.cache.store = ActiveSupport::Cache::RedisStore.new(redis: redis)
  
  # IP制限
  blocklist('block_bad_ips') do |req|
    ['192.168.1.100', '10.0.0.1'].include?(req.ip)
  end
  
  # 管理画面ログインの制限
  throttle('admin_login', limit: 5, period: 1.hour) do |req|
    if req.path == '/admin_auth/admin_users/sign_in' && req.post?
      req.ip
    end
  end
  
  # 一般APIの制限
  throttle('api_global', limit: 300, period: 5.minutes) do |req|
    req.ip if req.path.start_with?('/api/')
  end
  
  # 検索APIの制限
  throttle('api_search', limit: 60, period: 1.minute) do |req|
    req.ip if req.path.include?('/search')
  end
  
  # お問い合わせフォームの制限
  throttle('contact_form', limit: 5, period: 1.hour) do |req|
    req.ip if req.path == '/contacts' && req.post?
  end
end

# レスポンス設定
ActiveSupport::Notifications.subscribe('rack.attack') do |name, start, finish, request_id, payload|
  req = payload[:request]
  Rails.logger.warn "Rack::Attack #{req.env['rack.attack.match_type']} #{req.ip} #{req.request_method} #{req.fullpath}"
end
```

### 4. セキュリティヘッダー

#### セキュアヘッダー設定
```ruby
# config/application.rb
config.force_ssl = true if Rails.env.production?

# セキュリティヘッダー
config.action_dispatch.default_headers = {
  'X-Frame-Options' => 'SAMEORIGIN',
  'X-XSS-Protection' => '1; mode=block',
  'X-Content-Type-Options' => 'nosniff',
  'X-Download-Options' => 'noopen',
  'X-Permitted-Cross-Domain-Policies' => 'none',
  'Referrer-Policy' => 'strict-origin-when-cross-origin',
  'Permissions-Policy' => 'geolocation=(), microphone=(), camera=()'
}
```

#### HSTS設定
```ruby
# config/environments/production.rb
config.ssl_options = {
  hsts: {
    expires: 1.year,
    subdomains: true,
    preload: true
  }
}
```

### 5. データ暗号化

#### 機密データの暗号化
```ruby
# 暗号化された属性
class AdminUser < ApplicationRecord
  encrypts :api_token
  encrypts :two_factor_secret
  
  # データベース暗号化（Rails 7.0+）
  encrypts :personal_data, deterministic: false
end

# Credentials管理
class CredentialsService
  def self.secret_key_base
    Rails.application.credentials.secret_key_base
  end
  
  def self.database_password
    Rails.application.credentials.dig(:database, :password)
  end
  
  def self.openai_api_key
    Rails.application.credentials.dig(:openai, :api_key)
  end
end
```

### 6. ログ・監査

#### セキュリティイベントログ
```ruby
class SecurityEvent < ApplicationRecord
  belongs_to :admin_user, optional: true
  
  enum event_type: {
    login_success: 'login_success',
    login_failure: 'login_failure',
    password_change: 'password_change',
    account_locked: 'account_locked',
    permission_denied: 'permission_denied',
    data_access: 'data_access',
    api_access: 'api_access'
  }
  
  scope :recent, -> { where(created_at: 1.month.ago..) }
  scope :suspicious, -> { where(event_type: ['login_failure', 'permission_denied']) }
end

# セキュリティロガー
class SecurityLogger
  def self.log_event(type, user: nil, ip: nil, details: {})
    SecurityEvent.create!(
      event_type: type,
      admin_user: user,
      ip_address: ip,
      details: details,
      user_agent: details[:user_agent],
      created_at: Time.current
    )
  end
end
```

#### ログ設定
```ruby
# config/environments/production.rb
config.log_level = :info
config.log_tags = [:request_id, :remote_ip]

# Sentryエラー監視
config.before_initialize do
  Sentry.init do |config|
    config.dsn = Rails.application.credentials.sentry_dsn
    config.breadcrumbs_logger = [:active_support_logger, :http_logger]
    config.traces_sample_rate = 0.1
    config.release = ENV['APP_VERSION']
  end
end
```

### 7. ファイルアップロードセキュリティ

#### Active Storage設定
```ruby
# config/storage.yml
development:
  service: Disk
  root: <%= Rails.root.join("tmp/storage") %>

production:
  service: S3
  access_key_id: <%= Rails.application.credentials.dig(:aws, :access_key_id) %>
  secret_access_key: <%= Rails.application.credentials.dig(:aws, :secret_access_key) %>
  region: ap-northeast-1
  bucket: portfolio-production-uploads

# ファイル検証
class ImageUploader < ApplicationRecord
  has_one_attached :image
  
  validates :image, 
    content_type: { in: %w[image/jpeg image/jpg image/png image/gif] },
    size: { less_than: 5.megabytes }
  
  # ウイルススキャン（将来実装）
  # before_save :scan_for_viruses
  
  private
  
  def scan_for_viruses
    # ClamAVなどでのスキャン
  end
end
```

### 8. 侵入検知・防止

#### 異常検知
```ruby
class AnomalyDetector
  def self.detect_suspicious_activity(user, request)
    # 異常なログイン頻度
    if user.sign_in_count > 100 && user.current_sign_in_at > 1.hour.ago
      SecurityLogger.log_event('suspicious_login_frequency', user: user, ip: request.ip)
    end
    
    # 地理的異常
    if location_changed_dramatically?(user, request)
      SecurityLogger.log_event('suspicious_location_change', user: user, ip: request.ip)
    end
    
    # 通常と異なるユーザーエージェント
    if unusual_user_agent?(user, request)
      SecurityLogger.log_event('suspicious_user_agent', user: user, ip: request.ip)
    end
  end
end
```

## セキュリティ運用

### 定期セキュリティタスク

#### 日次タスク
- ログの確認
- 異常なアクセスパターンの検知
- システムリソース監視

#### 週次タスク
- セキュリティイベントの分析
- アクセスログの詳細分析
- 不要なアカウント・セッションのクリーンアップ

#### 月次タスク
- 依存関係の脆弱性チェック
- セキュリティ設定の見直し
- バックアップデータの検証

#### 四半期タスク
- ペネトレーションテスト
- セキュリティポリシーの見直し
- インシデント対応計画の更新

### インシデント対応

#### インシデント分類
1. **Level 1 (Critical)**: データ漏洩、システム侵害
2. **Level 2 (High)**: サービス停止、権限昇格
3. **Level 3 (Medium)**: セキュリティ警告、異常なアクセス
4. **Level 4 (Low)**: 設定不備、軽微な脆弱性

#### 対応手順
1. **初期対応**: インシデントの確認と影響範囲の特定
2. **封じ込め**: 被害の拡大防止
3. **根本原因分析**: 原因の特定と修正
4. **復旧**: システムの安全な復旧
5. **事後対応**: 再発防止策の実装

## コンプライアンス

### データ保護法対応
- **個人情報保護法**: 個人データの適切な取り扱い
- **GDPR準拠**: EU居住者データの保護（将来対応）

### セキュリティ標準準拠
- **OWASP Top 10**: Webアプリケーションセキュリティ
- **CWE/SANS Top 25**: 危険なソフトウェアエラー対策