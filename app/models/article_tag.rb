class ArticleTag < ApplicationRecord
  belongs_to :article
  belongs_to :tag

  after_create :refresh_tag_count
  after_destroy :refresh_tag_count

  private

  def refresh_tag_count
    tag.refresh_article_count!
  end
end
