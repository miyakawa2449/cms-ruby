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
  include Positionable
  include JsonStorable

  # Section type constants (定義順序重要)
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
    "hero" => "ヒーローセクション",
    "timeline" => "タイムライン概要",
    "chapter_1" => "第1章: パソコンスクール講師時代",
    "chapter_2" => "第2章: SE/PM・ビジネス分析者時代",
    "chapter_3" => "第3章: AI活用エンジニア時代",
    "skills_integration" => "スキル統合セクション",
    "projects" => "実績・事例セクション",
    "cta" => "Call to Action"
  }.freeze

  # Virtual attributes for form input (chapter sections)
  attr_accessor :skills, :achievements, :quote

  # Active Storage attachments
  has_one_attached :background_image
  has_one_attached :chapter_image
  has_many_attached :gallery_images

  # Validations
  validates :section_type, presence: true,
                          inclusion: {
                            in: SECTION_TYPES,
                            message: "%{value} is not a valid section type"
                          },
                          uniqueness: true
  validates :title, presence: true, length: { maximum: 255 }
  validates :subtitle, length: { maximum: 255 }
  validate :validate_with_custom_validator

  # Scopes
  scope :active, -> { where(is_active: true) }
  scope :inactive, -> { where(is_active: false) }
  scope :by_position, -> { order(:position) }
  scope :active_by_position, -> { active.by_position }

  # Class methods
  def self.section_type_options
    SECTION_TYPES.map { |type| [ SECTION_TYPE_LABELS[type], type ] }
  end

  def self.find_by_section_type(type)
    find_by(section_type: type)
  end

  def self.hero_section
    find_by_section_type("hero")
  end

  def self.timeline_section
    find_by_section_type("timeline")
  end

  def self.chapter_sections
    where(section_type: %w[chapter_1 chapter_2 chapter_3]).active_by_position
  end

  def self.skills_integration_section
    find_by_section_type("skills_integration")
  end

  def self.projects_section
    find_by_section_type("projects")
  end

  def self.cta_section
    find_by_section_type("cta")
  end

  # Service delegation methods
  def json_manager
    @json_manager ||= MyStorySectionJsonManager.new(self)
  end

  def position_manager
    @position_manager ||= MyStorySectionPositionManager.new(self)
  end

  def validator
    @validator ||= MyStorySectionValidator.new(self)
  end

  # JSON data delegation
  delegate :timeline_years, :timeline_years=,
           :chapter_skills, :chapter_skills=,
           :chapter_achievements, :chapter_achievements=,
           :chapter_quote, :chapter_quote=,
           :project_items, :project_items=,
           :cta_buttons, :cta_buttons=,
           :skills_list, :skills_list=,
           to: :json_manager

  # Position management delegation
  delegate :move_up, :move_down, :move_to_position,
           :move_to_last, :move_to_first,
           to: :position_manager

  # Instance methods
  def section_type_label
    SECTION_TYPE_LABELS[section_type] || section_type.humanize
  end

  def chapter_section?
    section_type.start_with?("chapter_")
  end

  def hero_section?
    section_type == "hero"
  end

  def timeline_section?
    section_type == "timeline"
  end

  def skills_integration_section?
    section_type == "skills_integration"
  end

  def projects_section?
    section_type == "projects"
  end

  def cta_section?
    section_type == "cta"
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
  before_save :sync_chapter_fields_to_additional_data
  after_initialize :load_chapter_fields_from_additional_data

  private

  def set_default_position
    return if position.present?

    self.position = self.class.next_position
  end

  # Load virtual attributes from additional_data when record is loaded
  def load_chapter_fields_from_additional_data
    return unless section_type.present? && chapter_section?

    @skills = chapter_skills.join("\n") if chapter_skills.any?
    @achievements = chapter_achievements.join("\n") if chapter_achievements.any?
    @quote = chapter_quote
  end

  # Sync virtual attributes to additional_data before save
  def sync_chapter_fields_to_additional_data
    return unless section_type.present? && chapter_section?

    self.additional_data ||= {}

    # Parse skills from textarea (newline-separated)
    if @skills.present?
      self.additional_data["skills"] = @skills.to_s.split(/[\r\n]+/).map(&:strip).reject(&:blank?)
    end

    # Parse achievements from textarea (newline-separated)
    if @achievements.present?
      self.additional_data["achievements"] = @achievements.to_s.split(/[\r\n]+/).map(&:strip).reject(&:blank?)
    end

    # Set quote directly
    if @quote.present?
      self.additional_data["quote"] = @quote.to_s.strip
    end
  end

  def validate_with_custom_validator
    return unless validator.validate_all

    validator.errors.each do |field, messages|
      messages.each { |message| errors.add(field, message) }
    end
  end
end
