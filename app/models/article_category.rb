class ArticleCategory < ApplicationRecord
  belongs_to :article
  belongs_to :category
  
  after_create :update_category_count
  after_destroy :update_category_count
  
  private
  
  def update_category_count
    category.update_column(:article_count, category.articles.count)
  end
end
