class Tag < ApplicationRecord
  include CacheSweeper

  has_many :article_tags, dependent: :destroy
  has_many :articles, through: :article_tags

  validates :name, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 50 }
  validates :slug, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 50 }

  scope :popular, -> { where("article_count > 0").order(article_count: :desc) }
  scope :alphabetical, -> { order(:name) }
  scope :with_published_articles, -> { joins(:articles).where(articles: { status: "published" }).distinct }
  scope :ordered_by_count, -> { order(article_count: :desc) }

  before_validation :generate_slug, if: -> { name_changed? && slug.blank? }

  # タグ生成の唯一の入り口（S1-7 P1-3で一本化）。
  # 大文字小文字を無視して既存タグを再利用し、無ければ入力の表記のまま作成する。
  # 作成に失敗した場合はログを残してnilを返す（呼び出し側はfilter_mapで除外する想定）
  def self.find_or_create_by_name(name)
    normalized = name.to_s.strip
    return nil if normalized.blank?

    existing = find_by("LOWER(name) = ?", normalized.downcase)
    return existing if existing

    tag = create(name: normalized)
    return tag if tag.persisted?

    Rails.logger.warn("Tag creation failed for '#{normalized}': #{tag.errors.full_messages.join(', ')}")
    nil
  end

  def to_param
    slug
  end

  # article_count = 公開中(published)の記事数（2026-07-15仕様確定）
  def refresh_article_count!
    update_column(:article_count, articles.published.count)
  end

  private

  def generate_slug
    base_slug = name.parameterize

    # 日本語などparameterizeで空になる場合はBase64エンコード（URL安全）を使用
    if base_slug.blank?
      # URLセーフなBase64でエンコード（短縮版）
      require "digest"
      base_slug = "tag-#{Digest::SHA256.hexdigest(name)[0, 8]}"
    end

    self.slug = base_slug

    # 重複チェックして番号を付加
    counter = 1
    while Tag.where(slug: self.slug).where.not(id: self.id).exists?
      self.slug = "#{base_slug}-#{counter}"
      counter += 1
    end
  end

  # CacheSweeper implementation
  def clear_related_caches
    # サイドバータグキャッシュをクリア
    clear_cache("sidebar/tags")

    # 記事一覧キャッシュをクリア
    clear_cache_matched("articles/page-*")
    clear_cache_matched("blog/page-*")

    Rails.logger.info "[CacheSweeper] Cleared caches for Tag##{id}"
  end
end
