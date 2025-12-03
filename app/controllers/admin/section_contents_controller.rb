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
    params.require(:section_content).permit(:content, :is_active)
  end
end