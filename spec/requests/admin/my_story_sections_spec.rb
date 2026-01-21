require 'rails_helper'

RSpec.describe 'Admin::MyStorySections', type: :request do
  let(:admin_user) { create(:admin_user) }

  before do
    sign_in admin_user, scope: :admin_user
    MyStorySection.delete_all
  end

  it 'renders index' do
    get admin_my_story_sections_path

    expect(response).to have_http_status(:success)
  end

  it 'shows a section' do
    section = create(:my_story_section, section_type: 'hero')

    get admin_my_story_section_path(section)

    expect(response).to have_http_status(:success)
  end

  it 'creates a section' do
    expect {
      post admin_my_story_sections_path, params: {
        my_story_section: {
          section_type: 'timeline',
          title: 'Hero Title',
          subtitle: 'Sub',
          content: 'Body',
          position: 0
        }
      }
    }.to change(MyStorySection, :count).by(1)
  end

  it 'updates a section' do
    section = create(:my_story_section, section_type: 'hero')

    patch admin_my_story_section_path(section), params: {
      my_story_section: { title: 'Updated Title' }
    }

    expect(section.reload.title).to eq('Updated Title')
  end

  it 'destroys a section' do
    section = create(:my_story_section, section_type: 'hero')

    expect {
      delete admin_my_story_section_path(section)
    }.to change(MyStorySection, :count).by(-1)
  end

  it 'moves section up and down' do
    section_a = create(:my_story_section, section_type: 'hero', position: 0)
    section_b = create(:my_story_section, section_type: 'timeline', position: 1)

    patch move_up_admin_my_story_section_path(section_b)
    expect(section_b.reload.position).to eq(0)

    patch move_down_admin_my_story_section_path(section_b)
    expect(section_b.reload.position).to eq(1)
  end

  it 'toggles active state' do
    section = create(:my_story_section, section_type: 'hero', is_active: true)

    patch toggle_active_admin_my_story_section_path(section)

    expect(section.reload.is_active).to eq(false)
  end

  it 'redirects when section is not found' do
    get admin_my_story_section_path('999999')

    expect(response).to redirect_to(admin_my_story_sections_path)
  end
end
