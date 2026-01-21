# Phase 6: Part 2 - 実装ガイド

**Phase**: 6  
**Part**: 2/4  
**作成日**: 2026-01-22  
**担当**: Codex

---

## 📋 実装の進め方

Phase 6 の実装は、以下の順序で進めてください：

1. セキュリティヘッダーの実装
2. SecurityLogger サービスの実装
3. Rack::Attack 設定の最適化
4. 入力検証・サニタイゼーションの強化

---

## 🔧 Task 1: セキュリティヘッダーの実装

### 1.1 Content Security Policy (CSP) の更新

**ファイル**: `config/initializers/content_security_policy.rb`

**現状**: 開発環境のみ設定

**目標**: 本番環境用の厳格な CSP 設定

```ruby
# config/initializers/content_security_policy.rb

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

**実装のポイント**:
- 開発環境と本番環境で設定を分ける
- 本番環境では厳格な設定
- 開発環境では `unsafe-eval`, `unsafe-inline` を許可（Turbo対応）

### 1.2 その他のセキュリティヘッダーの設定

**ファイル**: `config/initializers/security_headers.rb`（新規作成）

```ruby
# config/initializers/security_headers.rb

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

**実装のポイント**:
- HSTS は本番環境のみ有効化
- `force_ssl = true` で HTTPS を強制
- `preload: true` で HSTS Preload List に登録可能

---

## 🔧 Task 2: SecurityLogger サービスの実装

### 2.1 SecurityLogger サービスの作成

**ファイル**: `app/services/security_logger.rb`（新規作成）

```ruby
# app/services/security_logger.rb

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

**実装のポイント**:
- クラスメソッドで実装（インスタンス化不要）
- JSON 形式でログ出力（構造化ログ）
- severity レベルで分類（info, warning, error）
- タイムスタンプ、環境、IP アドレスを記録

### 2.2 AdminUser モデルへの Devise コールバック追加

**ファイル**: `app/models/admin_user.rb`（既存ファイルに追加）

```ruby
# app/models/admin_user.rb

class AdminUser < ApplicationRecord
  devise :database_authenticatable, :recoverable, :rememberable, 
         :validatable, :trackable, :lockable, :timeoutable
  
  # 既存のコード...
  
  # Devise コールバック（追加）
  def after_database_authentication
    SecurityLogger.log_login_success(self, Devise.sign_in_request) if Devise.sign_in_request
  end
  
  # Warden コールバック（追加）
  Warden::Manager.after_set_user do |user, auth, opts|
    if user.is_a?(AdminUser) && opts[:event] == :authentication
      SecurityLogger.log_login_success(user, auth.request)
    end
  end
  
  Warden::Manager.before_failure do |env, opts|
    if opts[:scope] == :admin_user
      email = env['warden.options'][:email] || env['action_dispatch.request.parameters']['admin_user']['email']
      SecurityLogger.log_login_failure(email, Rack::Request.new(env))
    end
  end
end
```

**実装のポイント**:
- Warden コールバックを使用（Devise の内部機構）
- ログイン成功/失敗を自動的にログ記録
- request オブジェクトを SecurityLogger に渡す

**注意**: Devise のコールバックは複雑なので、実装時に既存のコードを確認してください。

### 2.3 Rack::Attack へのログ記録追加

**ファイル**: `config/initializers/rack_attack.rb`（既存ファイルに追加）

```ruby
# config/initializers/rack_attack.rb

# 既存のコード...

# Rack::Attack のイベント通知（追加）
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

**実装のポイント**:
- ActiveSupport::Notifications を使用
- Rack::Attack のイベントを購読
- レート制限超過時に自動的にログ記録

---

## 🔧 Task 3: Rack::Attack 設定の最適化

### 3.1 Redis キャッシュの設定

**ファイル**: `config/initializers/rack_attack.rb`（既存ファイルを更新）

```ruby
# config/initializers/rack_attack.rb

class Rack::Attack
  # Redis を使用（本番環境）
  if Rails.env.production?
    Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(
      url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/1')
    )
  else
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
  end
  
  # 既存のコード...
end
```

**実装のポイント**:
- 本番環境では Redis を使用（スケーラビリティ）
- 開発環境では MemoryStore を使用（シンプル）
- 環境変数 `REDIS_URL` で設定

### 3.2 ホワイトリストの追加

```ruby
# config/initializers/rack_attack.rb

class Rack::Attack
  # 既存のコード...
  
  # ホワイトリスト（管理者IP）
  safelist('allow from admin IPs') do |req|
    admin_ips = ENV.fetch('ADMIN_WHITELIST_IPS', '').split(',')
    admin_ips.include?(req.ip) if admin_ips.any?
  end
  
  # 既存のコード...
end
```

**実装のポイント**:
- 環境変数 `ADMIN_WHITELIST_IPS` で管理者 IP を設定
- カンマ区切りで複数 IP を指定可能
- ホワイトリストの IP はレート制限を受けない

### 3.3 レート制限の調整

```ruby
# config/initializers/rack_attack.rb

class Rack::Attack
  # 既存のコード...
  
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
  
  # 既存のコード...
end
```

**実装のポイント**:
- 認証済みユーザーは緩いレート制限（300回/分）
- 未認証ユーザーは厳しいレート制限（60回/分）
- 管理画面への不正アクセスは厳しく制限（10回/分）

---

## 🔧 Task 4: 入力検証・サニタイゼーションの強化

### 4.1 Markdown サニタイゼーションの確認

**ファイル**: `app/helpers/markdown_helper.rb`（既存ファイルを確認）

**確認ポイント**:
- `sanitize` メソッドが使用されているか
- 許可タグ・属性が適切か
- XSS 対策が機能しているか

**推奨設定**:
```ruby
# app/helpers/markdown_helper.rb

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

### 4.2 ファイルアップロード検証の実装

**ファイル**: `app/models/concerns/media_validatable.rb`（新規作成）

```ruby
# app/models/concerns/media_validatable.rb

# メディアファイルのバリデーション
module MediaValidatable
  extend ActiveSupport::Concern
  
  ALLOWED_IMAGE_TYPES = %w[image/jpeg image/png image/gif image/webp].freeze
  MAX_FILE_SIZE = 10.megabytes
  
  included do
    validate :validate_image_content_type, if: -> { image.attached? }
    validate :validate_image_file_size, if: -> { image.attached? }
  end
  
  private
  
  def validate_image_content_type
    unless ALLOWED_IMAGE_TYPES.include?(image.content_type)
      errors.add(:image, "は JPEG、PNG、GIF、WebP 形式のみアップロード可能です")
    end
    
    # MIME タイプと実際のファイル内容の一致を確認
    begin
      actual_type = Marcel::MimeType.for(image.blob.download)
      unless image.blob.content_type == actual_type
        errors.add(:image, "のファイル形式が不正です")
      end
    rescue => e
      Rails.logger.error("File type validation error: #{e.message}")
      errors.add(:image, "の検証中にエラーが発生しました")
    end
  end
  
  def validate_image_file_size
    if image.blob.byte_size > MAX_FILE_SIZE
      errors.add(:image, "のサイズは #{MAX_FILE_SIZE / 1.megabyte}MB 以下にしてください")
    end
  end
end
```

**実装のポイント**:
- MIME タイプの検証
- ファイルサイズの検証
- ファイル内容の検証（Marcel gem を使用）
- エラーハンドリング

### 4.3 既存モデルへの適用

**ファイル**: `app/models/media_metadata.rb`（既存ファイルに追加）

```ruby
# app/models/media_metadata.rb

class MediaMetadata < ApplicationRecord
  include MediaValidatable  # 追加
  
  # 既存のコード...
end
```

---

## 📝 実装時の注意事項

### セキュリティ上の注意

1. **環境変数の管理**: 本番環境の環境変数は `.env.production` で管理（gitignore対象）
2. **ログの保護**: セキュリティログには個人情報が含まれるため、適切に保護
3. **段階的な導入**: セキュリティ設定は段階的に導入し、影響を監視

### パフォーマンス上の注意

1. **Redis の使用**: 本番環境では Rack::Attack のキャッシュに Redis を使用
2. **ログの最適化**: ログ記録による処理時間への影響を最小化
3. **ヘッダーサイズ**: CSP ヘッダーが大きくなりすぎないよう注意

### テスト時の注意

1. **レート制限のリセット**: テスト後はレート制限をリセット
2. **ログの確認**: テスト実行時のログを確認
3. **環境の分離**: 開発環境と本番環境で設定を分ける

---

## 🚀 次のステップ

Part 2 を読み終えたら、Part 3（テストガイド）に進んでください。

```
reports/2026-01-22/codex-phase6-part3-testing.md
```

---

**作成者**: Kiro（仕様管理担当）  
**作成日**: 2026-01-22  
**次のステップ**: Part 3 を読む
