class SectionContent < ApplicationRecord
  belongs_to :section
  belongs_to :publisher, class_name: "AdminUser", foreign_key: :published_by, optional: true
  
  validates :content, presence: true
  validates :version, presence: true, uniqueness: { scope: :section_id }
  validates :version, numericality: { greater_than: 0 }
  
  scope :active, -> { where(is_active: true) }
  scope :by_version, -> { order(:version) }
  
  before_validation :set_next_version, if: :new_record?
  before_save :deactivate_other_versions, if: :is_active_changed?
  
  def activate!
    transaction do
      section.section_contents.where(is_active: true).update_all(is_active: false)
      update!(is_active: true, published_at: Time.current, published_by: Current.admin_user&.id)
    end
  end
  
  def deactivate!
    update!(is_active: false)
  end
  
  private
  
  def set_next_version
    return if version.present?
    
    max_version = section.section_contents.maximum(:version) || 0
    self.version = max_version + 1
  end
  
  def deactivate_other_versions
    return unless is_active?
    
    section.section_contents.where.not(id: id).update_all(is_active: false)
  end
end
