class Admin::ContactsController < Admin::BaseController
  before_action :set_contact, only: [ :show, :edit, :update, :destroy ]

  def index
    @contacts = Contact.includes(:admin_user).recent
    @contacts = @contacts.where(status: params[:status]) if params[:status].present?
    @contacts = @contacts.where(subject: params[:subject]) if params[:subject].present?
    @contacts = @contacts.not_spam unless params[:show_spam] == "true"
  end

  def show
    @contact.mark_as_read! if @contact.unread?
  end

  def edit
  end

  def update
    # ステータス更新の場合は専用メソッドを使用
    if params[:contact] && params[:contact][:status]
      case params[:contact][:status]
      when "read"
        @contact.mark_as_read!
        redirect_to admin_contact_path(@contact), notice: "既読にしました。"
      when "replied"
        @contact.mark_as_replied!
        redirect_to admin_contact_path(@contact), notice: "返信済みにしました。"
      when "archived"
        @contact.update!(status: "archived")
        redirect_to admin_contact_path(@contact), notice: "アーカイブしました。"
      else
        @contact.update!(contact_params)
        redirect_to admin_contact_path(@contact), notice: "お問い合わせを更新しました。"
      end
    elsif @contact.update(contact_params)
      redirect_to admin_contact_path(@contact), notice: "お問い合わせを更新しました。"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @contact.destroy
    redirect_to admin_contacts_path, notice: "お問い合わせを削除しました。"
  end

  private

  def set_contact
    @contact = Contact.find(params[:id])
  end

  def contact_params
    params.require(:contact).permit(:status, :assigned_to, :notes)
  end
end
