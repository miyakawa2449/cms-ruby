class Category < ApplicationRecord
  include Positionable
  include CacheSweeper

  belongs_to :parent, class_name: "Category", optional: true
  has_many :children, class_name: "Category", foreign_key: :parent_id, dependent: :destroy

  has_many :article_categories, dependent: :destroy
  has_many :articles, through: :article_categories

  validates :name, presence: true, uniqueness: true, length: { maximum: 100 }
  validates :slug, presence: true, uniqueness: true, length: { maximum: 100 }
  validates :color, format: { with: /\A#[0-9A-Fa-f]{6}\z/ }, allow_blank: true

  scope :root_categories, -> { where(parent_id: nil) }
  scope :with_published_articles, -> { joins(:articles).where(articles: { status: "published" }).distinct }

  before_validation :generate_slug, if: -> { name_changed? && slug.blank? }

  # article_count = 公開中(published)の記事数（2026-07-15仕様確定）
  def refresh_article_count!
    update_column(:article_count, articles.published.count)
  end

  def root?
    parent_id.nil?
  end

  def leaf?
    children.empty?
  end

  def descendants
    children.includes(:children)
  end

  def full_name
    parent ? "#{parent.name} > #{name}" : name
  end

  private

  def generate_slug
    self.slug = name.parameterize
  end

  # CacheSweeper implementation
  def clear_related_caches
    # サイドバーカテゴリキャッシュをクリア
    clear_cache("sidebar/categories")

    # 記事一覧キャッシュをクリア
    clear_cache_matched("articles/page-*")
    clear_cache_matched("blog/page-*")

    Rails.logger.info "[CacheSweeper] Cleared caches for Category##{id}"
  end
end
