class Article < ApplicationRecord
  belongs_to :admin_user
  
  has_many :article_categories, dependent: :destroy
  has_many :categories, through: :article_categories
  has_many :article_tags, dependent: :destroy
  has_many :tags, through: :article_tags
  
  validates :title, presence: true, length: { maximum: 255 }
  validates :slug, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 255 }
  validates :content, presence: true
  validates :status, presence: true, inclusion: { in: %w[draft published scheduled archived] }
  
  scope :published, -> { where(status: 'published', published_at: ..Time.current) }
  scope :draft, -> { where(status: 'draft') }
  scope :recent, -> { order(published_at: :desc) }
  scope :by_category, ->(category) { joins(:categories).where(categories: { id: category }) }
  scope :by_tag, ->(tag) { joins(:tags).where(tags: { id: tag }) }
  scope :search_by_content, ->(query) { where("title ILIKE ? OR content ILIKE ? OR excerpt ILIKE ?", "%#{query}%", "%#{query}%", "%#{query}%") }
  
  before_validation :generate_slug, if: -> { title_changed? && slug.blank? }
  before_save :set_published_at, if: -> { status_changed? && status == 'published' }
  after_save :update_tag_counts
  after_destroy :update_tag_counts
  
  def published?
    status == 'published' && published_at.present? && published_at <= Time.current
  end
  
  def draft?
    status == 'draft'
  end
  
  def scheduled?
    status == 'scheduled' && published_at.present? && published_at > Time.current
  end
  
  def category_names
    categories.pluck(:name)
  end
  
  def tag_names
    tags.pluck(:name)
  end
  
  def tag_names=(names)
    tag_list = names.split(',').map(&:strip).reject(&:blank?)
    self.tags = tag_list.map do |name|
      # 大文字小文字を無視して既存タグを検索
      existing_tag = Tag.find_by('LOWER(name) = ?', name.downcase)
      existing_tag || Tag.create!(name: name)
    end
  end
  
  private
  
  def generate_slug
    base_slug = title.parameterize
    self.slug = base_slug
    
    # 重複チェックして番号を付加
    counter = 1
    while Article.where(slug: self.slug).where.not(id: self.id).exists?
      self.slug = "#{base_slug}-#{counter}"
      counter += 1
    end
  end
  
  def set_published_at
    self.published_at ||= Time.current
  end
  
  def update_category_counts
    categories.find_each { |category| category.update_column(:article_count, category.articles.count) }
  end
  
  def update_tag_counts
    tags.find_each { |tag| tag.update_column(:article_count, tag.articles.count) }
  end
end
