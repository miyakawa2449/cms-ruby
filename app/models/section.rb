class Section < ApplicationRecord
  has_many :section_contents, dependent: :destroy
  has_one :active_content, -> { where(is_active: true) }, class_name: "SectionContent"
  
  validates :name, presence: true, uniqueness: true, length: { maximum: 100 }
  validates :display_name, presence: true, length: { maximum: 100 }
  validates :position, presence: true, numericality: { greater_than_or_equal_to: 0 }
  
  scope :visible, -> { where(is_visible: true) }
  scope :ordered, -> { order(:position) }
  
  def active_content_data
    active_content&.content || {}
  end
  
  def published?
    active_content.present?
  end
end
