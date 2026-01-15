class ContactsController < ApplicationController
  # CSRFトークンの検証をスキップ（API使用時）
  # protect_from_forgery with: :null_session, only: [:create]

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
