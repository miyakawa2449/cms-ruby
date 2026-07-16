class PasskeyMailer < ApplicationMailer
  # パスキー登録時の通知（本人以外による登録の検知手段。仕様FR-4）
  def registered(admin_user, nickname)
    @nickname = nickname
    mail(to: admin_user.email, subject: "【セキュリティ通知】パスキーが登録されました")
  end

  # パスキー削除時の通知
  def removed(admin_user, nickname)
    @nickname = nickname
    mail(to: admin_user.email, subject: "【セキュリティ通知】パスキーが削除されました")
  end

  # クローン検知（sign_count逆行）の警告
  def clone_detected(admin_user, nickname)
    @nickname = nickname
    mail(to: admin_user.email, subject: "【重要・セキュリティ警告】パスキーの複製の疑いを検知しました")
  end
end
