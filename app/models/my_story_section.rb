# == Schema Information
#
# Table name: my_story_sections
#
#  id               :bigint           not null, primary key
#  section_type     :string           not null
#  title            :string           not null  
#  subtitle         :string
#  content          :text
#  additional_data  :jsonb            default({})
#  position         :integer          not null, default(0)
#  is_active        :boolean          not null, default(true)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_my_story_sections_on_section_type              (section_type) UNIQUE
#  index_my_story_sections_on_position                  (position)
#  index_my_story_sections_on_is_active                 (is_active)
#  index_my_story_sections_on_is_active_and_position    (is_active,position)
#  index_my_story_sections_on_additional_data           (additional_data) USING gin
#

class MyStorySection < ApplicationRecord
  # Active Storage attachments
  has_one_attached :background_image
  has_one_attached :chapter_image
  has_many_attached :gallery_images

  # Validations
  validates :section_type, presence: true, 
                          inclusion: { 
                            in: %w[hero timeline chapter_1 chapter_2 chapter_3 skills_integration projects cta],
                            message: "%{value} is not a valid section type" 
                          },
                          uniqueness: true
  validates :title, presence: true, length: { maximum: 255 }
  validates :subtitle, length: { maximum: 255 }
  validates :position, presence: true, numericality: { greater_than_or_equal_to: 0 }
  
  # Scopes
  scope :active, -> { where(is_active: true) }
  scope :inactive, -> { where(is_active: false) }
  scope :by_position, -> { order(:position) }
  scope :active_by_position, -> { active.by_position }

  # Section type constants
  SECTION_TYPES = %w[
    hero
    timeline
    chapter_1
    chapter_2
    chapter_3
    skills_integration
    projects
    cta
  ].freeze

  SECTION_TYPE_LABELS = {
    'hero' => 'ヒーローセクション',
    'timeline' => 'タイムライン概要',
    'chapter_1' => '第1章: パソコンスクール講師時代',
    'chapter_2' => '第2章: SE/PM・ビジネス分析者時代',
    'chapter_3' => '第3章: AI活用エンジニア時代',
    'skills_integration' => 'スキル統合セクション',
    'projects' => '実績・事例セクション',
    'cta' => 'Call to Action'
  }.freeze

  # Class methods
  def self.section_type_options
    SECTION_TYPES.map { |type| [SECTION_TYPE_LABELS[type], type] }
  end

  def self.find_by_section_type(type)
    find_by(section_type: type)
  end

  def self.hero_section
    find_by_section_type('hero')
  end

  def self.timeline_section
    find_by_section_type('timeline')
  end

  def self.chapter_sections
    where(section_type: %w[chapter_1 chapter_2 chapter_3]).active_by_position
  end

  def self.skills_integration_section
    find_by_section_type('skills_integration')
  end

  def self.projects_section
    find_by_section_type('projects')
  end

  def self.cta_section
    find_by_section_type('cta')
  end

  # Instance methods
  def section_type_label
    SECTION_TYPE_LABELS[section_type] || section_type.humanize
  end

  def chapter_section?
    section_type.start_with?('chapter_')
  end

  def hero_section?
    section_type == 'hero'
  end

  def timeline_section?
    section_type == 'timeline'
  end

  def skills_integration_section?
    section_type == 'skills_integration'
  end

  def projects_section?
    section_type == 'projects'
  end

  def cta_section?
    section_type == 'cta'
  end

  # Additional data accessors (JSONB fields)
  def timeline_years
    years = additional_data['years']
    case years
    when Array
      years
    when String
      years.present? ? [years] : []
    else
      []
    end
  end

  def timeline_years=(years)
    additional_data['years'] = years
  end

  def chapter_skills
    skills = additional_data['skills']
    case skills
    when Array
      skills
    when String
      skills.present? ? [skills] : []
    else
      []
    end
  end

  def chapter_skills=(skills)
    additional_data['skills'] = skills
  end

  def chapter_achievements
    achievements = additional_data['achievements']
    case achievements
    when Array
      achievements
    when String
      achievements.present? ? [achievements] : []
    else
      []
    end
  end

  def chapter_achievements=(achievements)
    additional_data['achievements'] = achievements
  end

  def chapter_quote
    additional_data['quote']
  end

  def chapter_quote=(quote)
    additional_data['quote'] = quote
  end

  def project_items
    items = additional_data.dig('projects', 'items')
    case items
    when Array
      items
    when String
      items.present? ? [items] : []
    else
      []
    end
  end

  def project_items=(items)
    additional_data['projects'] ||= {}
    additional_data['projects']['items'] = items
  end

  def cta_buttons
    buttons = additional_data.dig('cta', 'buttons')
    case buttons
    when Array
      buttons
    when String
      buttons.present? ? [buttons] : []
    else
      []
    end
  end

  def cta_buttons=(buttons)
    additional_data['cta'] ||= {}
    additional_data['cta']['buttons'] = buttons
  end

  def skills_list
    skills = additional_data.dig('skills', 'list')
    case skills
    when Array
      skills
    when String
      skills.present? ? [skills] : []
    else
      []
    end
  end

  def skills_list=(skills)
    additional_data['skills'] ||= {}
    additional_data['skills']['list'] = skills
  end

  # Image helpers
  def has_background_image?
    background_image.attached?
  end

  def has_chapter_image?
    chapter_image.attached?
  end

  def has_gallery_images?
    gallery_images.any?
  end

  # Callbacks
  before_validation :set_default_position, if: :new_record?

  private

  def set_default_position
    return if position.present?
    
    last_position = MyStorySection.maximum(:position) || 0
    self.position = last_position + 1
  end
end