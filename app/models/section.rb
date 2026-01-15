class Section < ApplicationRecord
  include Positionable
  include Publishable

  has_many :section_contents, dependent: :destroy
  has_one :active_content, -> { where(is_active: true) }, class_name: "SectionContent"

  validates :name, presence: true, uniqueness: true, length: { maximum: 100 }
  validates :display_name, presence: true, length: { maximum: 100 }

  scope :visible, -> { where(is_visible: true) }

  def active_content_data
    active_content&.content || {}
  end
end
