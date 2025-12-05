class Tag < ApplicationRecord
  has_many :article_tags, dependent: :destroy
  has_many :articles, through: :article_tags
  
  validates :name, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 50 }
  validates :slug, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 50 }
  
  scope :popular, -> { where('article_count > 0').order(article_count: :desc) }
  scope :alphabetical, -> { order(:name) }
  scope :with_published_articles, -> { joins(:articles).where(articles: { status: 'published' }).distinct }
  scope :ordered_by_count, -> { order(article_count: :desc) }
  
  before_validation :generate_slug, if: -> { name_changed? && slug.blank? }
  
  def to_param
    slug
  end
  
  private
  
  def generate_slug
    base_slug = name.parameterize
    self.slug = base_slug
    
    # 重複チェックして番号を付加
    counter = 1
    while Tag.where(slug: self.slug).where.not(id: self.id).exists?
      self.slug = "#{base_slug}-#{counter}"
      counter += 1
    end
  end
end
