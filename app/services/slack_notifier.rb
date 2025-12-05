class SlackNotifier
  include HTTParty
  
  def initialize(contact)
    @contact = contact
    @webhook_url = Rails.application.credentials.slack_webhook_url || ENV['SLACK_WEBHOOK_URL']
  end

  def send_notification
    return false unless @webhook_url.present?
    
    begin
      payload = build_payload
      response = HTTParty.post(@webhook_url, 
        body: payload.to_json,
        headers: { 'Content-Type' => 'application/json' }
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
      text: "🔔 新しいお問い合わせが届きました",
      attachments: [
        {
          color: "good",
          title: "お問い合わせ詳細",
          fields: [
            { title: "👤 お名前", value: @contact.name, short: true },
            { title: "📧 メールアドレス", value: @contact.email, short: true },
            { title: "📋 件名", value: @contact.subject, short: false },
            { title: "💬 メッセージ", value: truncate_message(@contact.message), short: false },
            { title: "🌐 IPアドレス", value: @contact.ip_address&.to_s || 'N/A', short: true },
            { title: "📅 受付日時", value: @contact.created_at.strftime('%Y年%m月%d日 %H:%M'), short: true }
          ],
          footer: "Portfolio Contact Form",
          footer_icon: "https://platform.slack-edge.com/img/default_application_icon.png",
          ts: @contact.created_at.to_i
        }
      ]
    }
  end

  def truncate_message(message)
    return 'N/A' unless message.present?
    
    if message.length > 300
      "#{message.first(300)}..."
    else
      message
    end
  end

  def create_notification_record(payload, success, error_message = nil)
    SlackNotification.create!(
      notification_type: 'contact',
      reference_id: @contact.id,
      reference_type: 'Contact',
      payload: payload.to_json,
      status: success ? 'sent' : 'failed',
      error_message: error_message,
      sent_at: success ? Time.current : nil
    )
  rescue => e
    Rails.logger.error "Failed to create slack notification record: #{e.message}"
  end
end