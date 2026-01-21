class PortfolioController < ApplicationController
  def index
    begin
      # セクションデータを取得し、コンテンツデータも事前に準備
      @sections = Section.visible.ordered.preload(
        active_content: [
          { profile_image_attachment: :blob },
          { hero_image_attachment: :blob },
          { background_image_attachment: :blob }
        ]
      )

      # 各セクションのコンテンツデータを事前に準備（ビューでのDB接続回避）
      @section_data = {}
      @sections.each do |section|
        begin
          @section_data[section.name] = section.active_content_data
        rescue => e
          Rails.logger.error "Error loading content for section #{section.name}: #{e.message}"
          @section_data[section.name] = {}
        end
      end

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
    rescue ActiveRecord::ConnectionNotEstablished => e
      Rails.logger.error "DB Connection Error in PortfolioController#index: #{e.message}"
      # 再接続を試行
      ActiveRecord::Base.establish_connection
      retry
    rescue => e
      Rails.logger.error "Error in PortfolioController#index: #{e.message}"
      @sections = []
      @section_data = {}
      @recent_articles = []
    end
  end
end
