class PortfolioController < ApplicationController
  def index
    # セクションデータを取得し、コンテンツデータも事前に準備
    @sections = Section.visible.ordered.preload(
      active_content: [
        { profile_image_attachment: :blob },
        { hero_image_attachment: :blob },
        { background_image_attachment: :blob }
      ]
    )

    # 各セクションのコンテンツデータを事前に準備（ビューでのDB接続回避）
    # 1セクションの不備でページ全体を落とさないよう、セクション単位でのみ握る
    @section_data = {}
    @sections.each do |section|
      @section_data[section.name] = section.active_content_data
    rescue => e
      Rails.logger.error "Error loading content for section #{section.name}: #{e.message}"
      @section_data[section.name] = {}
    end

    # Worksセクションの実績記事（公開日時の新しい順・最大6件）
    # 注意: order必須。無いと並び順がDB任せになり「ランダムに見える」バグになる
    @works_articles = Article.published
                             .joins(:categories)
                             .where(categories: { slug: "works" })
                             .order(published_at: :desc)
                             .includes(thumbnail_image_attachment: :blob)
                             .limit(6)
                             .to_a

    # ブログの最新記事を取得（Works記事除外）
    works_article_ids = Article.joins(:categories)
                               .where(categories: { slug: "works" })
                               .pluck(:id)

    @recent_articles = Article.published
                              .includes(:categories, :tags)
                              .where.not(id: works_article_ids)
                              .recent
                              .limit(3)

    # 検索機能追加
    if params[:search].present?
      @recent_articles = @recent_articles.search_by_content(params[:search])
      @search_query = params[:search]
    end
  end
end
