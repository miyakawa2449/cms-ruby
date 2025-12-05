class ContactNotificationJob < ApplicationJob
  queue_as :default

  def perform(contact)
    # Slack通知の送信
    SlackNotifier.new(contact).send_notification
    
    # メール通知の送信（必要に応じて）
    ContactMailer.new_contact_notification(contact).deliver_now if Rails.env.production?
  end
end
