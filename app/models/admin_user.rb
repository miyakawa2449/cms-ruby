# AdminUser model for portfolio site administration
# Phase 2A: 基本モデル定義（Phase 2BでDevise設定後に有効化）

class AdminUser < ApplicationRecord
  # Devise modules configuration
  # Phase 2Bで有効化予定:
  # devise :database_authenticatable, 
  #        :rememberable, :trackable, :timeoutable, :lockable,
  #        :recoverable, :confirmable, :validatable

  # === Associations ===
  has_many :articles, dependent: :nullify, foreign_key: :admin_user_id
  has_many :comments, through: :articles
  has_many :media_files, dependent: :nullify, foreign_key: :uploaded_by_id
  has_many :backups, dependent: :nullify, foreign_key: :created_by_id
  has_many :audit_logs, dependent: :nullify, foreign_key: :admin_user_id
  
  # === Validations ===
  validates :name, presence: true, length: { minimum: 2, maximum: 50 }
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, inclusion: { in: %w[super_admin admin editor viewer] }
  validates :status, inclusion: { in: %w[active inactive suspended] }
  
  # パスワード強度の検証（Phase 2Bで有効化）
  # validate :password_complexity, if: :password_required?
  
  # === Scopes ===
  scope :active, -> { where(status: 'active') }
  scope :inactive, -> { where(status: %w[inactive suspended]) }
  scope :by_role, ->(role) { where(role: role) }
  scope :recent, -> { order(created_at: :desc) }
  scope :last_signed_in, -> { order(last_sign_in_at: :desc) }
  
  # === Enums ===
  # Rails 7+ enum syntax
  enum :role, {
    super_admin: 'super_admin',
    admin: 'admin', 
    editor: 'editor',
    viewer: 'viewer'
  }, default: 'editor'
  
  enum :status, {
    active: 'active',
    inactive: 'inactive', 
    suspended: 'suspended'
  }, default: 'active'
  
  # === Callbacks ===
  before_validation :normalize_email
  before_create :set_default_settings
  after_create :send_welcome_email
  after_update :log_role_change, if: :saved_change_to_role?
  
  # === Class Methods ===
  
  def self.find_for_authentication(warden_conditions)
    # カスタム認証ロジック（Phase 2Bで実装）
    where(email: warden_conditions[:email], status: 'active').first
  end
  
  def self.roles_for_select
    roles.keys.map { |role| [role.humanize, role] }
  end
  
  def self.create_initial_admin!(email, password, name = 'Administrator')
    # 初期管理者作成用メソッド
    create!(
      email: email,
      password: password,
      password_confirmation: password,
      name: name,
      role: 'super_admin',
      status: 'active',
      confirmed_at: Time.current,
      settings: default_admin_settings
    )
  end
  
  def self.default_admin_settings
    {
      dashboard: {
        widgets: %w[stats recent_articles system_health],
        theme: 'light',
        language: 'ja'
      },
      notifications: {
        email_on_new_comment: true,
        email_on_system_alert: true,
        slack_notifications: false
      },
      editor: {
        auto_save: true,
        markdown_preview: true,
        spell_check: true
      }
    }
  end
  
  # === Instance Methods ===
  
  def display_name
    name.presence || email.split('@').first.humanize
  end
  
  def initials
    if name.present?
      name.split.map(&:first).join.upcase[0..1]
    else
      email[0..1].upcase
    end
  end
  
  def full_role_name
    role.humanize
  end
  
  def can_manage_users?
    super_admin? || admin?
  end
  
  def can_publish_articles?
    !viewer?
  end
  
  def can_manage_system?
    super_admin?
  end
  
  def can_access_analytics?
    super_admin? || admin?
  end
  
  def can_manage_backups?
    super_admin? || admin?
  end
  
  def can_edit_article?(article)
    return true if super_admin? || admin?
    return true if editor? && article.admin_user_id == id
    false
  end
  
  def active_for_authentication?
    # Devise用のアクティブ状態チェック
    super && active?
  end
  
  def inactive_message
    case status
    when 'inactive'
      :inactive
    when 'suspended'
      :suspended
    else
      super
    end
  end
  
  def last_activity
    [last_sign_in_at, updated_at].compact.max
  end
  
  def session_active?
    # セッションがアクティブかチェック（Phase 2Bで実装）
    return false unless last_sign_in_at
    last_sign_in_at > 24.hours.ago
  end
  
  def dashboard_stats
    # ダッシュボード用の統計情報
    {
      articles_count: articles.count,
      published_articles: articles.where(status: 'published').count,
      draft_articles: articles.where(status: 'draft').count,
      last_article: articles.order(:created_at).last,
      total_views: articles.sum(:views_count)
    }
  end
  
  def preference(key, default = nil)
    settings.dig(*key.to_s.split('.')) || default
  end
  
  def set_preference!(key_path, value)
    keys = key_path.to_s.split('.')
    nested_hash = keys[0..-2].inject(settings) { |hash, key| hash[key] ||= {} }
    nested_hash[keys.last] = value
    save!
  end
  
  # === Security Methods ===
  
  def generate_api_token!
    # API用のトークン生成（Phase 2Bで実装）
    token = SecureRandom.urlsafe_base64(32)
    update!(api_token: token, api_token_generated_at: Time.current)
    token
  end
  
  def revoke_api_token!
    update!(api_token: nil, api_token_generated_at: nil)
  end
  
  def api_token_valid?
    api_token.present? && api_token_generated_at > 30.days.ago
  end
  
  def increment_failed_attempts!
    self.failed_attempts ||= 0
    self.failed_attempts += 1
    
    if failed_attempts >= 5
      self.locked_at = Time.current
      self.status = 'suspended'
    end
    
    save!
  end
  
  def reset_failed_attempts!
    update!(failed_attempts: 0, locked_at: nil)
  end
  
  def locked?
    locked_at.present? && locked_at > 1.hour.ago
  end
  
  # === Audit Methods ===
  
  def log_activity(action, details = {})
    # 活動ログの記録（Phase 2Bで実装）
    # AuditLog.create!(
    #   admin_user: self,
    #   action: action,
    #   details: details,
    #   ip_address: Current.ip_address,
    #   user_agent: Current.user_agent
    # )
  end
  
  private
  
  def normalize_email
    self.email = email&.downcase&.strip
  end
  
  def set_default_settings
    self.settings ||= self.class.default_admin_settings
    self.timezone ||= 'Asia/Tokyo'
    self.language ||= 'ja'
  end
  
  def send_welcome_email
    # ウェルカムメール送信（Phase 2Bで実装）
    # AdminUserMailer.welcome_email(self).deliver_later
  end
  
  def log_role_change
    # ロール変更のログ記録
    log_activity('role_changed', { 
      from: role_before_last_save, 
      to: role 
    })
  end
  
  def password_required?
    # Devise用のパスワード必須チェック
    !persisted? || !password.nil? || !password_confirmation.nil?
  end
  
  def password_complexity
    # パスワード強度チェック（Phase 2Bで実装）
    return unless password.present?
    
    errors.add(:password, 'must contain at least one uppercase letter') unless password.match?(/[A-Z]/)
    errors.add(:password, 'must contain at least one lowercase letter') unless password.match?(/[a-z]/)
    errors.add(:password, 'must contain at least one digit') unless password.match?(/\d/)
    errors.add(:password, 'must contain at least one special character') unless password.match?(/[^A-Za-z0-9]/)
  end
end

# === Admin User Permissions Helper ===
# Phase 2Bで詳細な権限システムを実装予定

class AdminUserPermissions
  PERMISSIONS = {
    super_admin: %w[
      manage_users manage_system manage_backups
      manage_articles manage_comments manage_media
      view_analytics access_audit_logs
    ],
    admin: %w[
      manage_articles manage_comments manage_media
      view_analytics moderate_comments
    ],
    editor: %w[
      create_articles edit_own_articles manage_own_media
      moderate_comments
    ],
    viewer: %w[
      view_articles view_comments
    ]
  }.freeze
  
  def self.for_role(role)
    PERMISSIONS[role.to_sym] || []
  end
  
  def self.can?(user, permission)
    for_role(user.role).include?(permission.to_s)
  end
end