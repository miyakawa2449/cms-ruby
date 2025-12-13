class MyStoryController < ApplicationController
  # GET /my-story
  def index
    # My Story page logic - load dynamic sections
    @my_story_sections = MyStorySection.active_by_position.includes(
      background_image_attachment: :blob,
      chapter_image_attachment: :blob,
      gallery_images_attachments: :blob
    )
    
    # Cache sections by type for easy access in views
    @sections_by_type = @my_story_sections.index_by(&:section_type)
    
    # Extract specific sections for easier view access
    @hero_section = @sections_by_type['hero']
    @timeline_section = @sections_by_type['timeline']
    @chapter_sections = [
      @sections_by_type['chapter_1'],
      @sections_by_type['chapter_2'], 
      @sections_by_type['chapter_3']
    ].compact
    @skills_integration_section = @sections_by_type['skills_integration']
    @projects_section = @sections_by_type['projects']
    @cta_section = @sections_by_type['cta']
    
    # Load recent works for Projects section
    works_category = Category.find_by(slug: 'works')
    @recent_works = if works_category
                      Article.published.joins(:categories).where(categories: { id: works_category.id }).limit(3)
                    else
                      Article.published.limit(3)
                    end
    
    # Meta data for SEO
    @page_title = @hero_section&.title || "My Story"
    @page_description = @hero_section&.subtitle || "宮川 剛のキャリアストーリー"
  end
end