class Api::V1::SectionsController < Api::V1::BaseController
  before_action :set_section, only: [:show]
  
  # GET /api/v1/sections
  def index
    @sections = Section.includes(:active_content)
                      .visible
                      .ordered
    
    render_success(@sections.map { |section| SectionSerializer.new(section).serializable_hash })
  end
  
  # GET /api/v1/sections/:name
  def show
    render_success(SectionSerializer.new(@section, detailed: true).serializable_hash)
  end
  
  private
  
  def set_section
    name_param = params[:name] || params[:id]
    @section = Section.find_by!(name: name_param)
    
    # 非公開または公開コンテンツがないセクションは404
    raise ActiveRecord::RecordNotFound unless @section.is_visible? && @section.published?
  end
end