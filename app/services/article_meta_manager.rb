class ArticleMetaManager
  def initialize(article)
    @article = article
  end

  # Slug management
  def generate_slug(force: false)
    return if @article.slug.present? && !force
    return if @article.title.blank?

    base_slug = @article.title.parameterize
    @article.slug = generate_unique_slug(base_slug)
    save_article if @article.persisted?
  end

  def update_slug(new_title)
    return if new_title.blank?

    base_slug = new_title.parameterize
    @article.slug = generate_unique_slug(base_slug)
    save_article
  end

  def regenerate_slug!
    generate_slug(force: true)
  end

  # URL and routing
  def to_param
    @article.slug
  end

  def url_path
    if is_work_article?
      "/works/#{@article.slug}"
    else
      "/blog/#{@article.slug}"
    end
  end

  def canonical_url(base_url = nil)
    return url_path unless base_url
    "#{base_url.chomp('/')}#{url_path}"
  end

  # SEO meta data
  def seo_title(site_title: nil)
    title = @article.read_attribute(:meta_title).presence || @article.title
    return title unless site_title
    "#{title} | #{site_title}"
  end

  def seo_description
    @article.read_attribute(:meta_description).presence ||
    @article.read_attribute(:excerpt).presence ||
    content_manager.generate_excerpt(length: 160)
  end

  def seo_keywords
    keywords = []

    # メタキーワードがあれば使用
    if @article.read_attribute(:meta_keywords).present?
      keywords = @article.read_attribute(:meta_keywords).split(",").map(&:strip)
    else
      # タグとカテゴリから生成
      keywords.concat(@article.tags.pluck(:name))
      keywords.concat(@article.categories.pluck(:name))

      # 技術スタックがあれば追加
      tech_stack = @article.read_attribute(:tech_stack)
      if tech_stack.present?
        keywords.concat(tech_stack.split(",").map(&:strip).reject(&:blank?))
      end
    end

    keywords.uniq.reject(&:blank?)
  end

  # Open Graph / Twitter Card meta
  def og_title
    @article.read_attribute(:og_title).presence || @article.title
  end

  def og_description
    @article.read_attribute(:og_description).presence || seo_description
  end

  def og_image_url
    return nil unless @article.thumbnail_image.attached?

    # Active Storage URL生成は呼び出し元で処理
    @article.thumbnail_image
  end

  def twitter_card_type
    @article.thumbnail_image.attached? ? "summary_large_image" : "summary"
  end

  # Schema.org structured data
  def structured_data
    {
      "@context": "https://schema.org",
      "@type": "BlogPosting",
      "headline": @article.title,
      "description": seo_description,
      "author": {
        "@type": "Person",
        "name": @article.admin_user.email # 実際の名前フィールドがあれば使用
      },
      "datePublished": @article.published_at&.iso8601,
      "dateModified": @article.updated_at&.iso8601,
      "keywords": seo_keywords.join(", "),
      "articleSection": @article.categories.pluck(:name).join(", ")
    }
  end

  def structured_data_json
    structured_data.to_json
  end

  # Validation helpers
  def validate_slug_uniqueness
    return true if @article.slug.blank?

    duplicate = Article.where(slug: @article.slug)
                      .where.not(id: @article.id)
                      .exists?

    !duplicate
  end

  def slug_suggestion(base_title = nil)
    title = base_title || @article.title
    return nil if title.blank?

    base_slug = title.parameterize
    generate_unique_slug(base_slug)
  end

  private

  def save_article
    @article.save! if @article.persisted?
  end

  def content_manager
    @content_manager ||= ArticleContentManager.new(@article)
  end

  def is_work_article?
    @article.categories.exists?(slug: "works")
  end

  def generate_unique_slug(base_slug)
    slug = base_slug
    counter = 1

    while slug_exists?(slug)
      slug = "#{base_slug}-#{counter}"
      counter += 1
    end

    slug
  end

  def slug_exists?(slug)
    Article.where(slug: slug).where.not(id: @article.id).exists?
  end
end
