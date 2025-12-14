class SectionContent < ApplicationRecord
  belongs_to :section
  belongs_to :publisher, class_name: "AdminUser", foreign_key: :published_by, optional: true
  
  has_one_attached :hero_image
  has_one_attached :profile_image
  
  validates :content, presence: true, unless: :has_individual_fields?
  validates :version, presence: true, uniqueness: { scope: :section_id }
  validates :version, numericality: { greater_than: 0 }
  
  scope :active, -> { where(is_active: true) }
  scope :by_version, -> { order(:version) }
  
  before_validation :set_next_version, if: -> { new_record? && should_auto_set_version? }
  before_validation :set_empty_content_if_individual_fields
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
  
  def has_individual_fields?
    # Hero, About, My Story セクションは個別フィールドを使用
    case section&.name
    when 'hero'
      main_message.present? || sub_message.present? || career_description.present?
    when 'about'
      profile_text.present? || frontend_skills.present? || backend_skills.present? || core_skills.present? || experience_text.present?
    when 'my-story'
      badge_text.present? || main_title.present? || sub_title.present? || phase1_title.present? || phase2_title.present? || phase3_title.present?
    else
      false
    end
  end
  
  private
  
  def set_empty_content_if_individual_fields
    if has_individual_fields? && content.blank?
      self.content = {}
    end
  end
  
  def should_auto_set_version?
    # データベースのデフォルト値（1）が設定されている場合は自動設定する
    version.nil? || version == 1
  end
  
  def set_next_version
    return if version.present? && version != 1
    
    max_version = section.section_contents.maximum(:version) || 0
    self.version = max_version + 1
  end
  
  def deactivate_other_versions
    return unless is_active?
    
    section.section_contents.where.not(id: id).update_all(is_active: false)
  end
end
