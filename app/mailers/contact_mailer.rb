class ContactMailer < ApplicationMailer
  # 管理者への通知メール
  def admin_notification(contact)
    @contact = contact

    mail(
      to: ENV.fetch("ADMIN_EMAIL", "contact@miyakawa.codes"),
      subject: "[お問い合わせ] #{contact.subject} - #{contact.name}様より"
    )
  end

  # 問い合わせ者への自動返信メール
  def auto_reply(contact)
    @contact = contact

    mail(
      to: contact.email,
      subject: "【Miyakawa Codes】お問い合わせありがとうございます"
    )
  end
end
