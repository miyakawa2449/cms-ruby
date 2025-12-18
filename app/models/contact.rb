class Contact < ApplicationRecord
  belongs_to :admin_user, foreign_key: :assigned_to, optional: true

  # 個人情報の暗号化（Active Record Encryption）
  encrypts :email, deterministic: true  # 検索可能にするためdeterministic
  encrypts :name
  encrypts :message

  validates :name, presence: true, length: { maximum: 100 }
  validates :email, presence: true, 
                   format: { with: URI::MailTo::EMAIL_REGEXP }, 
                   length: { maximum: 255 }
  validates :subject, presence: true, length: { maximum: 255 }
  validates :message, presence: true, length: { maximum: 10000 }
  validates :status, presence: true, 
                    inclusion: { in: %w[unread read replied archived] }
  
  scope :unread, -> { where(status: 'unread') }
  scope :read, -> { where(status: 'read') }
  scope :replied, -> { where(status: 'replied') }
  scope :archived, -> { where(status: 'archived') }
  scope :recent, -> { order(created_at: :desc) }
  scope :not_spam, -> { where(is_spam: false) }
  
  before_save :sanitize_content
  after_create :send_notification
  
  def unread?
    status == 'unread'
  end
  
  def read?
    %w[read replied archived].include?(status)
  end
  
  def mark_as_read!
    update!(status: 'read') if unread?
  end
  
  def mark_as_replied!
    update!(status: 'replied', replied_at: Time.current)
  end
  
  private
  
  def sanitize_content
    self.message = ActionController::Base.helpers.sanitize(message)
    self.subject = ActionController::Base.helpers.sanitize(subject)
    self.name = ActionController::Base.helpers.sanitize(name)
  end
  
  def send_notification
    # 開発環境でも通知をテストできるように
    ContactNotificationJob.perform_later(self) if Rails.env.production? || ENV['ENABLE_NOTIFICATIONS'] == 'true'
  end
end
