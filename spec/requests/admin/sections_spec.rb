require 'rails_helper'

RSpec.describe 'Admin::Sections', type: :request do
  let(:admin_user) { create(:admin_user) }

  before do
    sign_in admin_user, scope: :admin_user
    SectionContent.delete_all
    Section.delete_all
    ActiveRecord::Base.connection.reset_pk_sequence!('section_contents')
    ActiveRecord::Base.connection.reset_pk_sequence!('sections')
  end

  it 'renders index' do
    get admin_sections_path

    expect(response).to have_http_status(:success)
  end

  it 'shows a section' do
    section = create(:section)

    get admin_section_path(section)

    expect(response).to have_http_status(:success)
  end

  it 'creates a section' do
    expect {
      post admin_sections_path, params: { section: attributes_for(:section) }
    }.to change(Section, :count).by(1)
  end

  it 'updates a section' do
    section = create(:section)

    patch admin_section_path(section), params: { section: { display_name: 'Updated' } }

    expect(section.reload.display_name).to eq('Updated')
  end

  it 'destroys a section' do
    section = create(:section)

    expect {
      delete admin_section_path(section)
    }.to change(Section, :count).by(-1)
  end
end
