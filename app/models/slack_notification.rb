class SlackNotification < ApplicationRecord
  validates :notification_type, presence: true, 
                               inclusion: { in: %w[contact article_published comment error] }
  validates :payload, presence: true
  validates :status, presence: true, 
                    inclusion: { in: %w[pending sent failed] }
  
  scope :pending, -> { where(status: 'pending') }
  scope :sent, -> { where(status: 'sent') }
  scope :failed, -> { where(status: 'failed') }
  scope :recent, -> { order(created_at: :desc) }
  
  # 関連先のレコードを動的に取得
  def reference
    return nil unless reference_type && reference_id
    reference_type.constantize.find_by(id: reference_id)
  end
  
  def sent?
    status == 'sent'
  end
  
  def failed?
    status == 'failed'
  end
  
  def pending?
    status == 'pending'
  end
end
