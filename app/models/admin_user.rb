class AdminUser < ApplicationRecord
  # NOTE: :registerable is intentionally disabled for security
  # Future: Re-enable when implementing multi-tenant CMS sales version
  # otp_secretはdevise-two-factor 6系がRails標準のActive Record Encryptionで暗号化する
  # （旧v4系のotp_secret_encryption_keyオプションは廃止済みのため指定しない）
  # :timeoutable は2026-07-16に廃止（剛さん決定）。
  # セッション寿命はクッキー有効期限24時間（session_store.rb）+ remember me 2週間で管理する
  devise :two_factor_authenticatable,
         :recoverable, :rememberable, :validatable,
         :lockable

  has_many :published_section_contents, class_name: "SectionContent", foreign_key: :published_by, dependent: :nullify
  has_many :articles, dependent: :destroy
  has_many :ai_generations, dependent: :nullify
  has_many :passkey_credentials, dependent: :destroy

  # WebAuthnのユーザーハンドル。初回アクセス時に生成して永続化する
  # （メールアドレス変更に影響されない安定した識別子）
  def webauthn_id
    super.presence || begin
      new_id = WebAuthn.generate_user_id
      update_column(:webauthn_id, new_id)
      new_id
    end
  end

  validates :email, presence: true, uniqueness: true

  after_commit :log_lock_state_change, if: :saved_change_to_locked_at?

  # ====================
  # 2FA Methods
  # ====================

  # Enable 2FA for this user
  def enable_two_factor!
    self.otp_secret = self.class.generate_otp_secret
    self.otp_required_for_login = true
    self.otp_enabled_at = Time.current
    save!
  end

  # Disable 2FA for this user
  def disable_two_factor!
    self.otp_secret = nil
    self.otp_required_for_login = false
    self.otp_enabled_at = nil
    self.otp_backup_codes = []
    save!
  end

  # Check if 2FA is enabled
  def two_factor_enabled?
    otp_required_for_login? && otp_secret.present?
  end

  # Generate 10 backup codes (returns plain codes, stores hashed codes)
  def generate_otp_backup_codes!
    codes = 10.times.map { SecureRandom.hex(5).upcase }
    hashed_codes = codes.map { |code| BCrypt::Password.create(code) }
    update!(otp_backup_codes: hashed_codes)
    codes
  end

  # Validate a backup code (removes it if valid)
  def validate_backup_code(code)
    return false if code.blank? || otp_backup_codes.blank?

    otp_backup_codes.each_with_index do |hashed_code, index|
      if BCrypt::Password.new(hashed_code) == code.upcase
        remaining_codes = otp_backup_codes.dup
        remaining_codes.delete_at(index)
        update!(otp_backup_codes: remaining_codes)
        return true
      end
    end
    false
  end

  # Accept backup codes as OTP attempts during login
  def validate_and_consume_otp!(code, options = {})
    return false if code.blank?

    normalized = code.to_s.strip
    return true if super(normalized, options)

    if validate_backup_code(normalized)
      # バックアップコードの使用と残数を管理者に通知する
      TwoFactorAuthMailer.backup_code_used(self, backup_codes_count).deliver_later
      true
    else
      false
    end
  end

  # Get remaining backup codes count
  def backup_codes_count
    otp_backup_codes&.size || 0
  end

  # ====================
  # Device Trust Methods
  # ====================


  private

  def log_lock_state_change
    if locked_at.present?
      SecurityLogger.log_account_locked(self, Current.request)
    else
      SecurityLogger.log_account_unlocked(self, Current.request)
    end
  end
end
