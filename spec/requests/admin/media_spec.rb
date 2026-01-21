require 'rails_helper'

RSpec.describe 'Admin::Media', type: :request do
  let(:admin_user) { create(:admin_user) }

  before do
    sign_in admin_user, scope: :admin_user
    allow_any_instance_of(MediaMetadata).to receive(:url).and_return('/blob')
  end

  it 'renders index and json' do
    media = build(:media_metadata)
    media.save!(validate: false)

    get admin_media_path
    expect(response).to have_http_status(:success)

    get admin_media_path(format: :json)
    expect(response).to have_http_status(:success)
  end

  it 'shows media in json' do
    media = build(:media_metadata)
    media.save!(validate: false)

    get admin_medium_path(media, format: :json)

    expect(response).to have_http_status(:success)
    expect(JSON.parse(response.body)['success']).to eq(true)
  end

  it 'creates media via upload service' do
    service = instance_double(Media::UploadService, call: { uploaded: [], failed: [] })
    allow(Media::UploadService).to receive(:new).and_return(service)

    post admin_media_path, params: { images: [] }, as: :json

    expect(response).to have_http_status(:success)
  end

  it 'updates media metadata' do
    allow_any_instance_of(MediaMetadata).to receive(:validate_blob_content_type).and_return(true)
    allow_any_instance_of(MediaMetadata).to receive(:validate_blob_file_size).and_return(true)
    media = build(:media_metadata)
    media.save!(validate: false)

    patch admin_medium_path(media), params: { media_metadata: { alt_text: 'Alt' } }, as: :json

    expect(response).to have_http_status(:success)
    expect(media.reload.alt_text).to eq('Alt')
  end

  it 'prevents deletion when used' do
    media = build(:media_metadata, usage_count: 2)
    media.save!(validate: false)

    delete admin_medium_path(media, format: :json)

    expect(response).to have_http_status(:unprocessable_entity)
  end

  it 'deletes unused media' do
    media = build(:media_metadata, usage_count: 0)
    media.save!(validate: false)

    allow(media.blob).to receive(:purge_later)

    expect {
      delete admin_medium_path(media, format: :json)
    }.to change(MediaMetadata, :count).by(-1)
  end

  it 'returns usage list' do
    media = build(:media_metadata)
    media.save!(validate: false)
    article = create(:article, :published, content: "blob #{media.blob.key}")

    get usage_admin_medium_path(media, format: :json)

    expect(response).to have_http_status(:success)
    expect(JSON.parse(response.body)['data']['articles'].first['id']).to eq(article.id)
  end

  it 'handles edit_image without upload' do
    media = build(:media_metadata)
    media.save!(validate: false)

    post edit_image_admin_medium_path(media), params: { save_as_new: 'true' }

    expect(response).to have_http_status(:unprocessable_entity)
  end

  it 'creates new media on edit_image when save_as_new is true' do
    media = build(:media_metadata)
    media.save!(validate: false)
    file = fixture_file_upload('spec/fixtures/files/test_image.jpg', 'image/jpeg')

    post edit_image_admin_medium_path(media), params: { save_as_new: 'true', image: file }, as: :multipart

    json = JSON.parse(response.body)
    expect(response).to have_http_status(:success)
    expect(json['data']['message']).to be_present
  end

  it 'updates existing media on edit_image when save_as_new is false' do
    media = build(:media_metadata)
    media.save!(validate: false)
    file = fixture_file_upload('spec/fixtures/files/test_image.jpg', 'image/jpeg')

    post edit_image_admin_medium_path(media), params: { save_as_new: 'false', image: file }, as: :multipart

    json = JSON.parse(response.body)
    expect(response).to have_http_status(:success)
    expect(json['data']['message']).to be_present
  end
end
