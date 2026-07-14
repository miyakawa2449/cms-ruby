require 'rails_helper'

RSpec.describe 'Admin::Tags', type: :request do
  let(:admin_user) { create(:admin_user) }

  before do
    sign_in admin_user, scope: :admin_user
  end

  it 'renders index' do
    get admin_tags_path

    expect(response).to have_http_status(:success)
  end

  it 'filters tags by search' do
    create(:tag, name: 'Rails')

    get admin_tags_path, params: { search: 'Rails' }

    expect(response).to have_http_status(:success)
  end

  it 'shows a tag' do
    tag = create(:tag)
    Tag.class_eval do
      def color
        nil
      end

      def icon
        nil
      end

      def description
        nil
      end
    end

    get admin_tag_path(tag)

    expect(response).to have_http_status(:success)
  end

  it 'creates a tag' do
    expect {
      post admin_tags_path, params: { tag: attributes_for(:tag) }
    }.to change(Tag, :count).by(1)
  end

  it 'updates a tag' do
    tag = create(:tag)
    new_name = "Updated-#{SecureRandom.hex(4)}"

    patch admin_tag_path(tag), params: { tag: { name: new_name } }

    expect(tag.reload.name).to eq(new_name)
  end

  it 'destroys a tag' do
    tag = create(:tag)

    expect {
      delete admin_tag_path(tag)
    }.to change(Tag, :count).by(-1)
  end
end
