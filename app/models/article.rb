class Article < ApplicationRecord
  include PgSearch::Model
  include Publishable
  include TrackableAttachment
  include CacheSweeper

  # pg_search full-text search configuration
  # Uses trigram for Japanese text support
  pg_search_scope :full_text_search,
    against: {
      title: "A",    # Highest priority
      excerpt: "B",  # Medium priority
      content: "C"   # Lower priority
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
  has_many :ai_generations, dependent: :destroy

  has_one_attached :thumbnail_image
  has_one_attached :ogp_image
  has_many_attached :content_images  # 本文内画像用

  validates :title, presence: true, length: { maximum: 255 }
  validates :slug, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 255 }
  validates :content, presence: true
  validates :status, presence: true, inclusion: { in: %w[draft published scheduled archived] }
  # 予約投稿には公開予定日時が必須（ないと永遠に公開されない「宙に浮いた」状態になる）
  validates :published_at, presence: true, if: -> { status == "scheduled" }

  enum :work_type, {
    standard: nil,
    github: "github",
    external_url: "external_url",
    internal: "internal"
  }, suffix: true

  scope :published, -> { where(status: "published", published_at: ..Time.current) }
  scope :draft, -> { where(status: "draft") }
  scope :recent, -> { order(published_at: :desc) }
  # タグフィルター（単数）
  scope :by_tag, ->(tag_id) {
    return all if tag_id.blank?
    joins(:article_tags).where(article_tags: { tag_id: tag_id })
  }
  scope :search_by_content, ->(query) { where("title ILIKE ? OR content ILIKE ? OR excerpt ILIKE ?", "%#{query}%", "%#{query}%", "%#{query}%") }
  scope :works, -> { joins(:categories).where(categories: { slug: "works" }) }
  scope :standard_blog, -> { joins(:categories).where.not(categories: { slug: "works" }) }

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
  # 公開状態が変わった時のみカウンタを更新（関連の増減はArticleCategory/ArticleTagの
  # コールバックが、記事削除は dependent: :destroy 経由で同コールバックが処理する）
  after_save :update_related_counts, if: -> { saved_change_to_status? || saved_change_to_published_at? }

  # has_many :through の一括置換（category_ids= 等）はjoinレコードをdelete_allで消すため
  # joinモデルのコールバックが発火しない。外された側も含めてカウントを明示的に更新する。
  def category_ids=(ids)
    affected = category_ids
    super
    Category.where(id: affected | category_ids).find_each(&:refresh_article_count!)
  end

  def categories=(records)
    affected = category_ids
    super
    Category.where(id: affected | category_ids).find_each(&:refresh_article_count!)
  end

  def tag_ids=(ids)
    affected = tag_ids
    super
    Tag.where(id: affected | tag_ids).find_each(&:refresh_article_count!)
  end

  def tags=(records)
    affected = tag_ids
    super
    Tag.where(id: affected | tag_ids).find_each(&:refresh_article_count!)
  end

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
    if status_changed? && status == "published"
      self.published_at ||= Time.current
    end
  end

  def update_related_counts
    categories.find_each(&:refresh_article_count!)
    tags.find_each(&:refresh_article_count!)
  end

  # CacheSweeper implementation
  def clear_related_caches
    # 記事一覧キャッシュをクリア
    clear_cache_matched("articles/page-*")
    clear_cache_matched("blog/page-*")

    # 人気記事キャッシュをクリア
    clear_cache("popular_articles")

    # サイドバーキャッシュをクリア（カテゴリ・タグに関連している可能性があるため）
    clear_cache("sidebar/categories")
    clear_cache("sidebar/tags")
    clear_cache("articles/published_count")

    Rails.logger.info "[CacheSweeper] Cleared caches for Article##{id}"
  end
end
