class Category < ApplicationRecord
  belongs_to :parent, class_name: "Category", optional: true
  has_many :children, class_name: "Category", foreign_key: :parent_id, dependent: :destroy
  
  has_many :article_categories, dependent: :destroy
  has_many :articles, through: :article_categories
  
  validates :name, presence: true, uniqueness: true, length: { maximum: 100 }
  validates :slug, presence: true, uniqueness: true, length: { maximum: 100 }
  validates :color, format: { with: /\A#[0-9A-Fa-f]{6}\z/ }, allow_blank: true
  validates :position, numericality: { greater_than_or_equal_to: 0 }
  
  scope :root_categories, -> { where(parent_id: nil) }
  scope :ordered, -> { order(:position, :name) }
  
  before_validation :generate_slug, if: -> { name_changed? && slug.blank? }
  after_commit :update_parent_article_count, if: :saved_change_to_article_count?
  
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
  
  def update_parent_article_count
    parent&.update_column(:article_count, parent.articles.count)
  end
end
