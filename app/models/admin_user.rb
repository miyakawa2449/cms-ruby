class AdminUser < ApplicationRecord
  # NOTE: :registerable is intentionally disabled for security
  # Future: Re-enable when implementing multi-tenant CMS sales version
  devise :two_factor_authenticatable,
         :recoverable, :rememberable, :validatable,
         :lockable, :timeoutable,
         otp_secret_encryption_key: ENV.fetch("OTP_SECRET_ENCRYPTION_KEY", Rails.application.secret_key_base[0..31])

  has_many :published_section_contents, class_name: "SectionContent", foreign_key: :published_by, dependent: :nullify
  has_many :articles, dependent: :destroy
  has_many :ai_generations, dependent: :nullify

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
    self.trusted_devices = []
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

    validate_backup_code(normalized)
  end

  # Get remaining backup codes count
  def backup_codes_count
    otp_backup_codes&.size || 0
  end

  # ====================
  # Device Trust Methods
  # ====================

  # Trust a device for 30 days
  def trust_device!(device_token)
    devices = trusted_devices || []
    devices << {
      "token" => device_token,
      "expires_at" => 30.days.from_now.iso8601,
      "trusted_at" => Time.current.iso8601
    }
    update!(trusted_devices: devices)
  end

  # Check if a device is trusted
  def device_trusted?(device_token)
    return false if device_token.blank? || trusted_devices.blank?

    trusted_devices.any? do |device|
      device["token"] == device_token &&
        Time.parse(device["expires_at"]) > Time.current
    end
  end

  # Remove expired trusted devices
  def cleanup_expired_devices!
    return if trusted_devices.blank?

    valid_devices = trusted_devices.select do |device|
      Time.parse(device["expires_at"]) > Time.current
    end
    update!(trusted_devices: valid_devices) if valid_devices.size != trusted_devices.size
  end

  # Revoke all trusted devices
  def revoke_all_trusted_devices!
    update!(trusted_devices: [])
  end

  private

  def log_lock_state_change
    if locked_at.present?
      SecurityLogger.log_account_locked(self, Current.request)
    else
      SecurityLogger.log_account_unlocked(self, Current.request)
    end
  end
end
