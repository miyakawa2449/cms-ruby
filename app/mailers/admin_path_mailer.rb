# frozen_string_literal: true

# Mailer for admin path URL change notifications
class AdminPathMailer < ApplicationMailer
  default from: -> { ENV.fetch("MAIL_FROM", "noreply@example.test") }

  # Notify when admin path is changed
  def path_changed(admin_user, old_path, new_path, change_type = "manual")
    @admin_user = admin_user
    @old_path = old_path
    @new_path = new_path
    @change_type = change_type
    @changed_at = Time.current

    mail(
      to: ENV.fetch("ADMIN_EMAIL", admin_user.email),
      subject: "[Important] Admin URL Changed"
    )
  end

  # Notify before automatic rotation
  def rotation_notification(admin_user, next_rotation_at)
    @admin_user = admin_user
    @next_rotation = next_rotation_at

    mail(
      to: ENV.fetch("ADMIN_EMAIL", admin_user.email),
      subject: "[Notice] Admin URL will be rotated in 24 hours"
    )
  end

  # Notify after emergency rotation
  def emergency_rotation(admin_user, old_path, new_path, reason)
    @admin_user = admin_user
    @old_path = old_path
    @new_path = new_path
    @reason = reason
    @rotated_at = Time.current

    mail(
      to: ENV.fetch("ADMIN_EMAIL", admin_user.email),
      subject: "[Urgent] Emergency Admin URL Rotation Completed"
    )
  end
end
