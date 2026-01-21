require 'rails_helper'

RSpec.describe 'MyStory', type: :request do
  before do
    MyStorySection.delete_all
  end

  it 'renders my story page with sections' do
    create(:my_story_section, section_type: 'hero', title: 'Hero')
    create(:my_story_section, section_type: 'timeline', title: 'Timeline')

    get my_story_path

    expect(response).to have_http_status(:success)
  end

  it 'loads recent works from works category when available' do
    works = Category.find_by(slug: 'works') || create(:category, slug: 'works')
    article = create(:article, :published)
    article.categories << works
    create(:my_story_section, section_type: 'hero', title: 'Hero')

    get my_story_path

    expect(response).to have_http_status(:success)
  end
end
