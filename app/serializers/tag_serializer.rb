class TagSerializer
  def initialize(tag, options = {})
    @tag = tag
    @detailed = options[:detailed] || false
  end

  def serializable_hash
    base_attributes = {
      id: @tag.id,
      name: @tag.name,
      slug: @tag.slug,
      article_count: @tag.article_count,
      urls: {
        self: "/api/v1/tags/#{@tag.id}",
        articles: "/api/v1/tags/#{@tag.id}/articles",
        web: "/blog?tag=#{@tag.id}"
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
      created_at: @tag.created_at.iso8601,
      updated_at: @tag.updated_at.iso8601
    }
  end
end
