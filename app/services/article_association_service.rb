# frozen_string_literal: true

# 記事のカテゴリ・タグ関連付け管理を担当するサービス
class ArticleAssociationService
  attr_reader :article

  def initialize(article)
    @article = article
  end

  def setup_for_form
    {
      categories: Category.ordered,
      available_tags: Tag.alphabetical,
      selected_category_ids: @article.category_ids,
      tag_names: @article.tag_names
    }
  end

  def process_associations(params)
    process_categories(params[:category_ids])
    process_tags(params[:tag_names])
  end

  def available_categories
    Category.ordered
  end

  def available_tags
    Tag.alphabetical
  end

  private

  def process_categories(category_ids)
    return unless category_ids.present?
    
    # 有効なカテゴリIDのみを設定
    valid_ids = Category.where(id: category_ids).pluck(:id)
    @article.category_ids = valid_ids
  end

  def process_tags(tag_names)
    return unless tag_names.present?
    
    # タグ名から既存タグを検索し、存在しない場合は新規作成
    tags = tag_names.split(',').map(&:strip).reject(&:blank?).map do |tag_name|
      Tag.find_or_create_by(name: tag_name.downcase)
    end
    
    @article.tags = tags
  end
end