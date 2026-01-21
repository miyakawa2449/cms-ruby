require 'rails_helper'

RSpec.describe 'Admin::SectionContents', type: :request do
  let(:admin_user) { create(:admin_user) }
  let(:section) { Section.find_by(name: 'hero') || create(:section, name: 'hero', display_name: 'Hero') }

  before do
    sign_in admin_user, scope: :admin_user
    SectionContent.delete_all
    ActiveRecord::Base.connection.reset_pk_sequence!('section_contents')
  end

  it 'renders new' do
    get new_admin_section_section_content_path(section)

    expect(response).to have_http_status(:success)
  end

  it 'creates section content' do
    expect {
      post admin_section_section_contents_path(section), params: {
        section_content: {
          main_message: 'Hello',
          content: '{"title":"Hero"}',
          is_active: false
        }
      }
    }.to change(SectionContent, :count).by(1)
  end

  it 'updates section content' do
    content = create(:section_content, section: section)

    patch admin_section_section_content_path(section, content), params: {
      section_content: { main_message: 'Updated' }
    }

    expect(response).to redirect_to(admin_section_path(section))
  end

  it 'destroys section content' do
    content = create(:section_content, section: section)

    expect {
      delete admin_section_section_content_path(section, content)
    }.to change(SectionContent, :count).by(-1)
  end

  it 'activates section content' do
    content = create(:section_content, section: section, is_active: false)

    patch activate_admin_section_section_content_path(section, content)

    expect(response).to redirect_to(admin_section_path(section))
    expect(content.reload.is_active).to eq(true)
  end
end
