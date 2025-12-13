class PortfolioController < ApplicationController
  def index
    begin
      # セクションデータを取得し、コンテンツデータも事前に準備
      @sections = Section.includes(:active_content).visible.ordered
      
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
      @recent_articles = Article.published
                                .includes(:categories, :tags)
                                .joins('LEFT JOIN article_categories ON articles.id = article_categories.article_id')
                                .joins('LEFT JOIN categories ON article_categories.category_id = categories.id')
                                .where('categories.slug IS NULL OR categories.slug != ?', 'works')
                                .recent
                                .limit(3)
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