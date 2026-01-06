class Article < ApplicationRecord
  include PgSearch::Model
  include Publishable
  include TrackableAttachment

  # pg_search full-text search configuration
  # Uses trigram for Japanese text support
  pg_search_scope :full_text_search,
    against: {
      title: 'A',    # Highest priority
      excerpt: 'B',  # Medium priority
      content: 'C'   # Lower priority
    },
    using: {
      trigram: {
        threshold: 0.1,  # Lower threshold for better recall
        word_similarity: true
      }
    },
    order_within_rank: "articles.published_at DESC"

  belongs_to :admin_user
  
  has_many :article_categories, dependent: :destroy
  has_many :categories, through: :article_categories
  has_many :article_tags, dependent: :destroy
  has_many :tags, through: :article_tags
  
  has_one_attached :thumbnail_image
  has_many_attached :content_images  # 本文内画像用
  
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
  # タグフィルター（単数）
  scope :by_tag, ->(tag_id) {
    return all if tag_id.blank?
    joins(:article_tags).where(article_tags: { tag_id: tag_id })
  }
  scope :search_by_content, ->(query) { where("title ILIKE ? OR content ILIKE ? OR excerpt ILIKE ?", "%#{query}%", "%#{query}%", "%#{query}%") }
  scope :works, -> { joins(:categories).where(categories: { slug: 'works' }) }
  scope :standard_blog, -> { joins(:categories).where.not(categories: { slug: 'works' }) }

  # 検索機能用スコープ（Phase 4.5 - pg_search full-text search）
  # Uses trigram-based search for Japanese text support
  scope :search, ->(query) {
    return all if query.blank?

    full_text_search(query.to_s.strip)
  }

  # Fallback ILIKE search (kept for backward compatibility)
  scope :search_ilike, ->(query) {
    return all if query.blank?

    sanitized_query = sanitize_sql_like(query.to_s.strip)
    where(
      "title ILIKE :q OR content ILIKE :q OR excerpt ILIKE :q",
      q: "%#{sanitized_query}%"
    )
  }

  # カテゴリフィルター（単数）
  scope :by_category, ->(category_id) {
    return all if category_id.blank?
    joins(:article_categories).where(article_categories: { category_id: category_id })
  }

  scope :by_tags, ->(tag_ids) {
    return all if tag_ids.blank?

    joins(:tags).where(tags: { id: tag_ids }).distinct
  }
  
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
