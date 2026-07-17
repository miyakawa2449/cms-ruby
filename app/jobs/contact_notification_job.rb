class ContactNotificationJob < ApplicationJob
  queue_as :default

  def perform(contact)
    # Slack通知の送信
    SlackNotifier.notify_contact(contact)

    # メール通知の送信（本番環境のみ）
    if Rails.env.production?
      # 管理者への通知
      ContactMailer.admin_notification(contact).deliver_now

      # 問い合わせ者への自動返信
      ContactMailer.auto_reply(contact).deliver_now
    end
  end
end
