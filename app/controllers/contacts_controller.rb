class ContactsController < ApplicationController
  # CSRF保護はApplicationControllerの protect_from_forgery with: :exception を継承する。
  # フロントの contact_form_controller.js は X-CSRF-Token ヘッダーを送信している。
  # 注意: ここで protect_from_forgery を再宣言すると親のverify_authenticity_token
  # コールバックが置き換えられ、条件外のリクエストが無検証になる（S1-7 P0-4で修正済み）

  def create
    # Honeypot check - ボットはこのフィールドを自動入力する
    if params[:contact][:website].present?
      # ボット判定：成功を返すが保存しない（ボットに気づかせない）
      Rails.logger.info "[SPAM] Honeypot triggered from IP: #{request.remote_ip}"
      return render json: {
        message: "お問い合わせを受け付けました。ご連絡をお待ちください。",
        status: "success"
      }, status: :created
    end

    @contact = Contact.new(contact_params)

    # IPアドレスとUser-Agentを記録
    @contact.ip_address = request.remote_ip
    @contact.user_agent = request.user_agent
    @contact.referrer = request.referer

    if @contact.save
      render json: {
        message: "お問い合わせを受け付けました。ご連絡をお待ちください。",
        status: "success"
      }, status: :created
    else
      render json: {
        message: "エラーが発生しました。",
        errors: @contact.errors.full_messages,
        status: "error"
      }, status: :unprocessable_entity
    end
  end

  private

  def contact_params
    params.require(:contact).permit(:name, :email, :subject, :message)
  end
end
