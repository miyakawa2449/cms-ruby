# frozen_string_literal: true

# Mailer for 2FA notifications
class TwoFactorAuthMailer < ApplicationMailer
  default from: -> { ENV.fetch("MAIL_FROM", "noreply@example.test") }

  # Notify when 2FA is enabled
  def enabled(admin_user)
    @admin_user = admin_user
    @enabled_at = Time.current

    mail(
      to: ENV.fetch("ADMIN_EMAIL", admin_user.email),
      subject: "[Security] Two-Factor Authentication Enabled"
    )
  end

  # Notify when 2FA is disabled
  def disabled(admin_user)
    @admin_user = admin_user
    @disabled_at = Time.current

    mail(
      to: ENV.fetch("ADMIN_EMAIL", admin_user.email),
      subject: "[Important] Two-Factor Authentication Disabled"
    )
  end

  # Notify when backup codes are regenerated
  def backup_codes_regenerated(admin_user)
    @admin_user = admin_user
    @regenerated_at = Time.current

    mail(
      to: ENV.fetch("ADMIN_EMAIL", admin_user.email),
      subject: "[Security] 2FA Backup Codes Regenerated"
    )
  end

  # Notify when a backup code is used
  def backup_code_used(admin_user, remaining_codes)
    @admin_user = admin_user
    @remaining_codes = remaining_codes
    @used_at = Time.current

    mail(
      to: ENV.fetch("ADMIN_EMAIL", admin_user.email),
      subject: "[Security] 2FA Backup Code Used - #{remaining_codes} codes remaining"
    )
  end
end
