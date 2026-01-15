class CategorySerializer
  def initialize(category, options = {})
    @category = category
    @detailed = options[:detailed] || false
  end

  def serializable_hash
    base_attributes = {
      id: @category.id,
      name: @category.name,
      slug: @category.slug,
      article_count: @category.article_count,
      urls: {
        self: "/api/v1/categories/#{@category.id}",
        articles: "/api/v1/categories/#{@category.id}/articles",
        web: "/blog?category=#{@category.id}"
      }
    }

    # 親カテゴリ情報
    if @category.parent_id.present?
      base_attributes[:parent] = {
        id: @category.parent.id,
        name: @category.parent.name,
        slug: @category.parent.slug
      }
    end

    if @detailed
      base_attributes.merge!(detailed_attributes)
    end

    base_attributes
  end

  private

  def detailed_attributes
    {
      description: @category.description,
      icon: @category.icon,
      color: @category.color,
      position: @category.position,
      created_at: @category.created_at.iso8601,
      updated_at: @category.updated_at.iso8601
    }
  end
end
