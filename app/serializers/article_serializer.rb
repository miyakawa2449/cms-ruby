class ArticleSerializer
  def initialize(article, options = {})
    @article = article
    @detailed = options[:detailed] || false
  end
  
  def serializable_hash
    base_attributes = {
      id: @article.id,
      title: @article.title,
      slug: @article.slug,
      excerpt: @article.excerpt,
      published_at: @article.published_at&.iso8601,
      reading_time: calculate_reading_time,
      view_count: 0,
      categories: categories_data,
      tags: tags_data,
      urls: {
        self: "/api/v1/articles/#{@article.slug}",
        web: "/blog/#{@article.slug}"
      }
    }
    
    if @detailed
      base_attributes.merge!(detailed_attributes)
    end
    
    base_attributes
  end
  
  private
  
  def detailed_attributes
    {
      content: @article.content,
      content_html: @article.content_html,
      meta_description: @article.meta_description,
      meta_keywords: @article.meta_keywords,
      og_title: @article.og_title,
      og_description: @article.og_description,
      og_image_url: @article.respond_to?(:og_image_url) ? @article.og_image_url : nil,
      ai_summary: nil,
      ai_keywords: nil,
      created_at: @article.created_at.iso8601,
      updated_at: @article.updated_at.iso8601
    }
  end
  
  def categories_data
    @article.categories.map do |category|
      {
        id: category.id,
        name: category.name,
        slug: category.slug,
        url: "/api/v1/categories/#{category.id}"
      }
    end
  end
  
  def tags_data
    @article.tags.map do |tag|
      {
        id: tag.id,
        name: tag.name,
        slug: tag.slug,
        url: "/api/v1/tags/#{tag.id}"
      }
    end
  end

  def calculate_reading_time
    return 0 unless @article.content.present?
    
    # 200 words per minute reading speed
    words_per_minute = 200
    word_count = @article.content.split.size
    
    (word_count.to_f / words_per_minute).ceil
  end
end