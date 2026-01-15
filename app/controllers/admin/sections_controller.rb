class Admin::SectionsController < Admin::BaseController
  before_action :set_section, only: [ :show, :edit, :update, :destroy ]

  def index
    @sections = Section.includes(:section_contents).ordered
  end

  def show
    @section_contents = @section.section_contents.includes(:publisher).by_version
  end

  def new
    @section = Section.new
  end

  def edit
  end

  def create
    @section = Section.new(section_params)

    if @section.save
      redirect_to admin_section_path(@section), notice: "セクションを作成しました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @section.update(section_params)
      redirect_to admin_section_path(@section), notice: "セクションを更新しました。"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @section.destroy
    redirect_to admin_sections_path, notice: "セクションを削除しました。"
  end

  private

  def set_section
    @section = Section.find(params[:id])
  end

  def section_params
    params.require(:section).permit(:name, :display_name, :is_visible, :position)
  end
end
