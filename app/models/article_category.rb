class ArticleCategory < ApplicationRecord
  belongs_to :article
  belongs_to :category

  after_create :refresh_category_count
  after_destroy :refresh_category_count

  private

  def refresh_category_count
    category.refresh_article_count!
  end
end
