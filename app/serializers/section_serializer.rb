class SectionSerializer
  def initialize(section, options = {})
    @section = section
    @detailed = options[:detailed] || false
  end
  
  def serializable_hash
    base_attributes = {
      id: @section.id,
      name: @section.name,
      display_name: @section.display_name,
      position: @section.position,
      is_visible: @section.is_visible,
      urls: {
        self: "/api/v1/sections/#{@section.name}",
        web: "/##{@section.name}"
      }
    }
    
    # アクティブなコンテンツがある場合は含める
    if @section.active_content.present?
      base_attributes[:content] = @section.active_content_data
      base_attributes[:published_at] = @section.active_content.published_at&.iso8601
    end
    
    if @detailed
      base_attributes.merge!(detailed_attributes)
    end
    
    base_attributes
  end
  
  private
  
  def detailed_attributes
    active_content = @section.active_content
    
    details = {
      created_at: @section.created_at.iso8601,
      updated_at: @section.updated_at.iso8601
    }
    
    if active_content
      details.merge!({
        content_version: active_content.version,
        content_updated_at: active_content.updated_at.iso8601,
        published_by: active_content.publisher&.email
      })
    end
    
    details
  end
end