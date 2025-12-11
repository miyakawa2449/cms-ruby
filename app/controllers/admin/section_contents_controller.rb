class Admin::SectionContentsController < Admin::BaseController
  before_action :set_section
  before_action :set_section_content, only: [:edit, :update, :destroy, :activate]
  
  def new
    @section_content = @section.section_contents.build
  end
  
  def edit
  end
  
  def create
    @section_content = @section.section_contents.build(section_content_params)
    @section_content.published_by = current_admin_user.id
    
    if @section_content.save
      redirect_to admin_section_path(@section), notice: "コンテンツを作成しました。"
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  def update
    if @section_content.update(section_content_params)
      redirect_to admin_section_path(@section), notice: "コンテンツを更新しました。"
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    @section_content.destroy
    redirect_to admin_section_path(@section), notice: "コンテンツを削除しました。"
  end
  
  def activate
    @section_content.activate!
    redirect_to admin_section_path(@section), notice: "コンテンツを公開しました。"
  rescue => e
    redirect_to admin_section_path(@section), alert: "公開に失敗しました: #{e.message}"
  end
  
  private
  
  def set_section
    @section = Section.find(params[:section_id])
  end
  
  def set_section_content
    @section_content = @section.section_contents.find(params[:id])
  end
  
  def section_content_params
    # 基本フィールドと画像を許可
    permitted_params = params.require(:section_content).permit(
      :is_active, :hero_image, :profile_image,
      :main_message, :sub_message, :career_description,
      :cta_primary_text, :cta_primary_url, :cta_secondary_text, :cta_secondary_url,
      :profile_text, :frontend_skills, :backend_skills, :core_skills, :experience_text,
      :badge_text, :main_title, :sub_title,
      :phase1_year, :phase1_title, :phase1_description, :phase1_period,
      :phase2_year, :phase2_title, :phase2_description, :phase2_period,
      :phase3_year, :phase3_title, :phase3_description, :phase3_period,
      :cta_button_text, :cta_description
    )
    
    # contentパラメータを処理
    content_data = {}
    
    if params[:section_content][:content].present?
      if params[:section_content][:content].is_a?(String)
        # 汎用JSON文字列の場合
        begin
          content_data = JSON.parse(params[:section_content][:content])
        rescue JSON::ParserError
          content_data = {}
        end
      elsif params[:section_content][:content].is_a?(ActionController::Parameters)
        # セクション固有のフィールドの場合
        content_params = params[:section_content][:content]
        
        # 基本フィールドを許可
        basic_fields = [:title, :subtitle, :description, :image_url, :cta_text, :cta_url, :email, :story, :posts_count]
        basic_fields.each do |field|
          content_data[field] = content_params[field] if content_params[field].present?
        end
        
        # JSONフィールドの処理
        json_fields = [:skills, :services, :works, :social_links]
        json_fields.each do |field|
          if content_params[field].present?
            begin
              content_data[field] = JSON.parse(content_params[field])
            rescue JSON::ParserError
              content_data[field] = []
            end
          end
        end
      end
    end
    
    permitted_params.merge(content: content_data)
  end
end