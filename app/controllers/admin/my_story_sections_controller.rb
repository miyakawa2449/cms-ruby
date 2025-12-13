class Admin::MyStorySectionsController < Admin::BaseController
  before_action :set_my_story_section, only: [:show, :edit, :update, :destroy, :move_up, :move_down, :toggle_active]

  def index
    @my_story_sections = MyStorySection.by_position.includes(
      background_image_attachment: :blob,
      chapter_image_attachment: :blob,
      gallery_images_attachments: :blob
    )
    
    # セクション統計
    @total_sections = @my_story_sections.count
    @active_sections = @my_story_sections.select(&:is_active).count
    @inactive_sections = @total_sections - @active_sections
  end

  def show
    @section_details = {
      has_background_image: @my_story_section.has_background_image?,
      has_chapter_image: @my_story_section.has_chapter_image?,
      has_gallery_images: @my_story_section.has_gallery_images?,
      additional_data_keys: @my_story_section.additional_data.keys
    }
  end

  def new
    @my_story_section = MyStorySection.new
    @available_section_types = available_section_types
  end

  def edit
    @available_section_types = available_section_types
  end

  def create
    @my_story_section = MyStorySection.new(my_story_section_params)
    @available_section_types = available_section_types

    if @my_story_section.save
      redirect_to admin_my_story_section_path(@my_story_section), 
                  notice: "My Storyセクション「#{@my_story_section.title}」を作成しました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @available_section_types = available_section_types

    if @my_story_section.update(my_story_section_params)
      redirect_to admin_my_story_section_path(@my_story_section),
                  notice: "My Storyセクション「#{@my_story_section.title}」を更新しました。"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    section_title = @my_story_section.title
    @my_story_section.destroy
    redirect_to admin_my_story_sections_path, 
                notice: "My Storyセクション「#{section_title}」を削除しました。"
  end

  def move_up
    current_position = @my_story_section.position
    previous_section = MyStorySection.where('position < ?', current_position)
                                   .order(position: :desc)
                                   .first

    if previous_section
      MyStorySection.transaction do
        @my_story_section.update!(position: previous_section.position)
        previous_section.update!(position: current_position)
      end
      redirect_to admin_my_story_sections_path, notice: "セクションの順序を上に移動しました。"
    else
      redirect_to admin_my_story_sections_path, alert: "これより上に移動できません。"
    end
  rescue ActiveRecord::RecordInvalid => e
    redirect_to admin_my_story_sections_path, alert: "移動に失敗しました: #{e.message}"
  end

  def move_down
    current_position = @my_story_section.position
    next_section = MyStorySection.where('position > ?', current_position)
                                .order(position: :asc)
                                .first

    if next_section
      MyStorySection.transaction do
        @my_story_section.update!(position: next_section.position)
        next_section.update!(position: current_position)
      end
      redirect_to admin_my_story_sections_path, notice: "セクションの順序を下に移動しました。"
    else
      redirect_to admin_my_story_sections_path, alert: "これより下に移動できません。"
    end
  rescue ActiveRecord::RecordInvalid => e
    redirect_to admin_my_story_sections_path, alert: "移動に失敗しました: #{e.message}"
  end

  def toggle_active
    @my_story_section.update!(is_active: !@my_story_section.is_active?)
    status_text = @my_story_section.is_active? ? "アクティブ" : "非アクティブ"
    redirect_to admin_my_story_sections_path, 
                notice: "セクション「#{@my_story_section.title}」を#{status_text}にしました。"
  rescue ActiveRecord::RecordInvalid => e
    redirect_to admin_my_story_sections_path, alert: "更新に失敗しました: #{e.message}"
  end

  private

  def set_my_story_section
    @my_story_section = MyStorySection.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_my_story_sections_path, alert: "指定されたセクションが見つかりません。"
  end

  def my_story_section_params
    params.require(:my_story_section).permit(
      :section_type,
      :title, 
      :subtitle,
      :content,
      :position,
      :is_active,
      :background_image,
      :chapter_image,
      gallery_images: [],
      additional_data: [
        timeline: [
          years: []
        ],
        chapter: [
          skills: [],
          achievements: [],
          quote: ""
        ],
        projects: [
          items: []
        ],
        cta: [
          buttons: []
        ],
        skills: [
          list: []
        ]
      ]
    )
  end

  def available_section_types
    existing_types = MyStorySection.pluck(:section_type)
    all_types = MyStorySection::SECTION_TYPES
    
    if @my_story_section&.persisted?
      # 編集時は現在のセクションタイプを含める
      available_types = all_types - existing_types + [@my_story_section.section_type]
    else
      # 新規作成時は既存のタイプを除外
      available_types = all_types - existing_types
    end
    
    available_types.map { |type| [MyStorySection::SECTION_TYPE_LABELS[type], type] }
  end
end