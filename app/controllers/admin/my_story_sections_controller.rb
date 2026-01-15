class Admin::MyStorySectionsController < Admin::BaseController
  before_action :set_my_story_section, only: [ :show, :edit, :update, :destroy, :move_up, :move_down, :toggle_active ]

  def index
    @my_story_sections = MyStorySection.by_position.includes(
      background_image_attachment: :blob,
      chapter_image_attachment: :blob,
      gallery_images_attachments: :blob
    )

    # 統計情報をサービスに委譲
    stats_service = MyStorySectionStatisticsService.new(@my_story_sections)
    stats = stats_service.section_index_stats
    @total_sections = stats[:total_sections]
    @active_sections = stats[:active_sections]
    @inactive_sections = stats[:inactive_sections]
  end

  def show
    # 詳細情報をサービスに委譲
    state_service = MyStorySectionStateService.new(@my_story_section)
    @section_details = state_service.section_details
  end

  def new
    @my_story_section = MyStorySection.new
    @available_section_types = MyStorySectionTypeService.available_types_for(@my_story_section)
  end

  def edit
    @available_section_types = MyStorySectionTypeService.available_types_for(@my_story_section)
  end

  def create
    @my_story_section = MyStorySection.new(my_story_section_params)
    @available_section_types = MyStorySectionTypeService.available_types_for(@my_story_section)

    if @my_story_section.save
      redirect_to admin_my_story_section_path(@my_story_section),
                  notice: "My Storyセクション「#{@my_story_section.title}」を作成しました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @available_section_types = MyStorySectionTypeService.available_types_for(@my_story_section)

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
    ordering_service = MyStorySectionOrderingService.new(@my_story_section)

    if ordering_service.move_up
      redirect_to admin_my_story_sections_path, notice: "セクションの順序を上に移動しました。"
    else
      redirect_to admin_my_story_sections_path, alert: ordering_service.error_messages
    end
  end

  def move_down
    ordering_service = MyStorySectionOrderingService.new(@my_story_section)

    if ordering_service.move_down
      redirect_to admin_my_story_sections_path, notice: "セクションの順序を下に移動しました。"
    else
      redirect_to admin_my_story_sections_path, alert: ordering_service.error_messages
    end
  end

  def toggle_active
    state_service = MyStorySectionStateService.new(@my_story_section)
    result = state_service.toggle_active

    if result[:success]
      redirect_to admin_my_story_sections_path, notice: result[:message]
    else
      redirect_to admin_my_story_sections_path, alert: result[:errors].join(", ")
    end
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
      :skills,        # 追加
      :achievements,  # 追加
      :quote,         # 追加
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
end
