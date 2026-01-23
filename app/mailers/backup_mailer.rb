# frozen_string_literal: true

# Mailer for backup status notifications
class BackupMailer < ApplicationMailer
  default from: -> { ENV.fetch("MAIL_FROM", "noreply@example.test") }

  # Notify when backup succeeds
  def backup_success(backup_log)
    @backup_log = backup_log
    @file_size_mb = backup_log.file_size.present? ? (backup_log.file_size.to_f / 1024 / 1024).round(2) : nil

    mail(
      to: ENV.fetch("ADMIN_EMAIL", "admin@example.test"),
      subject: "[Backup] #{backup_log.backup_type.capitalize} backup completed successfully"
    )
  end

  # Notify when backup fails
  def backup_failed(backup_log, error = nil)
    @backup_log = backup_log
    @error = error || backup_log.error_message

    mail(
      to: ENV.fetch("ADMIN_EMAIL", "admin@example.test"),
      subject: "[Urgent] #{backup_log.backup_type.capitalize} backup failed"
    )
  end

  # Notify when restore succeeds
  def restore_success(backup_log)
    @backup_log = backup_log
    @restored_at = Time.current

    mail(
      to: ENV.fetch("ADMIN_EMAIL", "admin@example.test"),
      subject: "[Backup] Restore completed successfully"
    )
  end

  # Notify when restore fails
  def restore_failed(backup_log, error = nil)
    @backup_log = backup_log
    @error = error

    mail(
      to: ENV.fetch("ADMIN_EMAIL", "admin@example.test"),
      subject: "[Urgent] Restore failed"
    )
  end
end
