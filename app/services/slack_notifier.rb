# Slack notification service for various events
# Supports contact notifications and Phase 7 security/operations notifications
class SlackNotifier
  include HTTParty

  class << self
    # Check if Slack notifications are enabled
    def enabled?
      webhook_url.present?
    end

    # Notify 2FA settings change
    def notify_2fa_changed(admin_user, action)
      return false if admin_user.blank? || action.blank?
      return false unless enabled?

      message = {
        text: "2FA Settings Changed",
        attachments: [ {
          color: action == "enabled" ? "good" : "warning",
          fields: [
            { title: "Admin", value: admin_user.email, short: true },
            { title: "Action", value: action == "enabled" ? "Enabled" : "Disabled", short: true },
            { title: "Timestamp", value: Time.current.strftime("%Y-%m-%d %H:%M:%S"), short: true }
          ]
        } ]
      }

      send_message(message, notification_type: "2fa_changed", reference: admin_user)
    end

    # Notify admin path URL change
    def notify_admin_path_changed(admin_user, old_path, new_path, change_type)
      return false if admin_user.blank? || old_path.blank? || new_path.blank? || change_type.blank?
      return false unless enabled?

      message = {
        text: "Admin URL Changed",
        attachments: [ {
          color: change_type == "emergency" ? "danger" : "warning",
          fields: [
            { title: "Changed By", value: admin_user.email, short: true },
            { title: "Change Type", value: change_type, short: true },
            { title: "Old URL", value: "/#{old_path}", short: true },
            { title: "New URL", value: "/#{new_path}", short: true },
            { title: "Timestamp", value: Time.current.strftime("%Y-%m-%d %H:%M:%S"), short: true }
          ]
        } ]
      }

      send_message(message, notification_type: "admin_path_changed", reference: admin_user)
    end

    # Notify backup status
    def notify_backup_status(backup_log)
      return false if backup_log.blank?
      return false unless enabled?

      color = case backup_log.status
      when "success" then "good"
      when "failed" then "danger"
      else "warning"
      end

      fields = [
        { title: "Type", value: backup_log.backup_type, short: true },
        { title: "Status", value: backup_log.status, short: true },
        { title: "Timestamp", value: backup_log.created_at.strftime("%Y-%m-%d %H:%M:%S"), short: true }
      ]

      if backup_log.file_size.present?
        size_mb = (backup_log.file_size.to_f / 1024 / 1024).round(2)
        fields << { title: "File Size", value: "#{size_mb} MB", short: true }
      end

      if backup_log.status == "failed" && backup_log.error_message.present?
        fields << { title: "Error", value: backup_log.error_message, short: false }
      end

      status_text = backup_log.status == "success" ? "Success" : "Failed"
      message = {
        text: "Backup #{status_text}",
        attachments: [ {
          color: color,
          fields: fields
        } ]
      }

      send_message(message, notification_type: "backup_status", reference: backup_log)
    end

    # Notify security vulnerability detected
    def notify_security_issue(audit_log)
      return false if audit_log.blank?
      return false unless enabled?

      message = {
        text: "Security Vulnerability Detected",
        attachments: [ {
          color: "danger",
          fields: [
            { title: "Audit Type", value: audit_log.audit_type, short: true },
            { title: "Issues Count", value: audit_log.issues_count.to_s, short: true },
            { title: "Status", value: audit_log.status, short: true },
            { title: "Timestamp", value: audit_log.created_at.strftime("%Y-%m-%d %H:%M:%S"), short: true }
          ]
        } ]
      }

      send_message(message, notification_type: "security_issue", reference: audit_log)
    end

    # Notify health check alert
    def notify_health_check_alert(check_type, status, metrics)
      return false if check_type.blank? || status.blank?
      return false unless enabled?

      color = status == "critical" ? "danger" : "warning"
      metrics_str = metrics.is_a?(Hash) ? metrics.map { |k, v| "#{k}: #{v}" }.join(", ") : metrics.to_s

      message = {
        text: "Health Check Alert",
        attachments: [ {
          color: color,
          fields: [
            { title: "Check Type", value: check_type, short: true },
            { title: "Status", value: status, short: true },
            { title: "Metrics", value: metrics_str, short: false },
            { title: "Timestamp", value: Time.current.strftime("%Y-%m-%d %H:%M:%S"), short: true }
          ]
        } ]
      }

      send_message(message, notification_type: "health_check_alert")
    end

    private

    def webhook_url
      Rails.application.credentials.slack_webhook_url || ENV["SLACK_WEBHOOK_URL"]
    end

    def send_message(payload, notification_type: nil, reference: nil)
      response = HTTParty.post(webhook_url,
        body: payload.to_json,
        headers: { "Content-Type" => "application/json" }
      )

      # Create notification record if reference provided
      if reference && notification_type
        create_notification_record(
          notification_type,
          reference,
          payload,
          response.success?
        )
      end

      response.success?
    rescue => e
      Rails.logger.error "Slack notification failed: #{e.message}"
      false
    end

    def create_notification_record(notification_type, reference, payload, success, error_message = nil)
      SlackNotification.create!(
        notification_type: notification_type,
        reference_id: reference.respond_to?(:id) ? reference.id : nil,
        reference_type: reference.class.name,
        payload: payload.to_json,
        status: success ? "sent" : "failed",
        error_message: error_message,
        sent_at: success ? Time.current : nil
      )
    rescue => e
      Rails.logger.error "Failed to create slack notification record: #{e.message}"
    end
  end

  # Instance methods for contact notifications (backward compatibility)
  def initialize(contact)
    @contact = contact
    @webhook_url = Rails.application.credentials.slack_webhook_url || ENV["SLACK_WEBHOOK_URL"]
  end

  def send_notification
    return false if @contact.blank?
    return false unless @webhook_url.present?

    begin
      payload = build_payload
      response = HTTParty.post(@webhook_url,
        body: payload.to_json,
        headers: { "Content-Type" => "application/json" }
      )

      # SlackNotificationレコード作成
      create_notification_record(payload, response.success?)

      response.success?
    rescue => e
      Rails.logger.error "Slack notification failed: #{e.message}"
      create_notification_record(build_payload, false, e.message)
      false
    end
  end

  private

  def build_payload
    {
      text: "New Contact Received",
      attachments: [
        {
          color: "good",
          title: "Contact Details",
          fields: [
            { title: "Name", value: @contact.name, short: true },
            { title: "Email", value: @contact.email, short: true },
            { title: "Subject", value: @contact.subject, short: false },
            { title: "Message", value: truncate_message(@contact.message), short: false },
            { title: "IP Address", value: @contact.ip_address&.to_s || "N/A", short: true },
            { title: "Received At", value: @contact.created_at.strftime("%Y-%m-%d %H:%M"), short: true }
          ],
          footer: "Portfolio Contact Form",
          footer_icon: "https://platform.slack-edge.com/img/default_application_icon.png",
          ts: @contact.created_at.to_i
        }
      ]
    }
  end

  def truncate_message(message)
    return "N/A" unless message.present?

    if message.length > 300
      "#{message.first(300)}..."
    else
      message
    end
  end

  def create_notification_record(payload, success, error_message = nil)
    SlackNotification.create!(
      notification_type: "contact",
      reference_id: @contact.id,
      reference_type: "Contact",
      payload: payload.to_json,
      status: success ? "sent" : "failed",
      error_message: error_message,
      sent_at: success ? Time.current : nil
    )
  rescue => e
    Rails.logger.error "Failed to create slack notification record: #{e.message}"
  end
end
