class Article < ApplicationRecord
  belongs_to :admin_user
  
  has_many :article_categories, dependent: :destroy
  has_many :categories, through: :article_categories
  has_many :article_tags, dependent: :destroy
  has_many :tags, through: :article_tags
  
  has_one_attached :thumbnail_image
  
  validates :title, presence: true, length: { maximum: 255 }
  validates :slug, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 255 }
  validates :content, presence: true
  validates :status, presence: true, inclusion: { in: %w[draft published scheduled archived] }
  
  enum :work_type, {
    standard: nil,
    github: 'github',
    external_url: 'external_url', 
    internal: 'internal'
  }, suffix: true
  
  scope :published, -> { where(status: 'published', published_at: ..Time.current) }
  scope :draft, -> { where(status: 'draft') }
  scope :recent, -> { order(published_at: :desc) }
  scope :by_category, ->(category) { joins(:categories).where(categories: { id: category }) }
  scope :by_tag, ->(tag) { joins(:tags).where(tags: { id: tag }) }
  scope :search_by_content, ->(query) { where("title ILIKE ? OR content ILIKE ? OR excerpt ILIKE ?", "%#{query}%", "%#{query}%", "%#{query}%") }
  scope :works, -> { joins(:categories).where(categories: { slug: 'works' }) }
  scope :standard_blog, -> { joins(:categories).where.not(categories: { slug: 'works' }) }
  
  before_validation :generate_slug_if_needed
  before_save :set_published_at_if_needed
  after_save :update_related_counts
  after_destroy :update_related_counts
  
  # Service delegation methods
  def content_manager
    @content_manager ||= ArticleContentManager.new(self)
  end

  def meta_manager
    @meta_manager ||= ArticleMetaManager.new(self)
  end

  def publishing_manager
    @publishing_manager ||= ArticlePublishingManager.new(self)
  end

  # Content management delegation
  delegate :tech_stack_list, :tech_stack_list=,
           :category_names, :tag_names,
           :is_work?, :content_word_count, :content_reading_time,
           to: :content_manager

  # Meta management delegation  
  delegate :to_param, :url_path, :canonical_url,
           :seo_title, :seo_description, :seo_keywords,
           :og_title, :og_description, :structured_data,
           to: :meta_manager

  # Publishing management delegation
  delegate :published?, :draft?, :scheduled?, :archived?,
           :publishable?, :status_display,
           to: :publishing_manager

  # Legacy method support for backward compatibility
  def tag_names=(names)
    content_manager.assign_tag_names(names)
  end
  
  private
  
  def generate_slug_if_needed
    meta_manager.generate_slug if title_changed? && slug.blank?
  end
  
  def set_published_at_if_needed
    if status_changed? && status == 'published'
      self.published_at ||= Time.current
    end
  end
  
  def update_related_counts
    update_category_counts
    update_tag_counts
  end

  def update_category_counts
    categories.find_each { |category| category.update_column(:article_count, category.articles.published.count) }
  end
  
  def update_tag_counts
    tags.find_each { |tag| tag.update_column(:article_count, tag.articles.published.count) }
  end
end
