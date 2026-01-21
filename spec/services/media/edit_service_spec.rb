require 'rails_helper'

RSpec.describe Media::EditService do
  let(:blob) { instance_double(ActiveStorage::Blob) }
  let(:media) do
    double(
      'MediaMetadata',
      id: 1,
      blob: blob,
      image?: true,
      mime_type: 'image/jpeg',
      alt_text: 'Alt',
      filename: 'photo.jpg'
    )
  end

  before do
    allow(Rails.application.routes.url_helpers).to receive(:rails_representation_path).and_return('/rails/variant')
    allow(Rails.application.routes.url_helpers).to receive(:rails_blob_path).and_return('/rails/blob')
  end

  it 'rejects invalid operations' do
    service = described_class.new(media, :invalid, {})

    expect(service.call).to eq(success: false, error: 'Invalid operation')
  end

  it 'rejects when media is missing or not an image' do
    service = described_class.new(nil, :crop, {})
    expect(service.call).to eq(success: false, error: 'Media not found')

    non_image = double('MediaMetadata', image?: false)
    service = described_class.new(non_image, :crop, {})
    expect(service.call).to eq(success: false, error: 'Not an image')
  end

  it 'crops image and returns variant url' do
    variant = instance_double(ActiveStorage::Variant)
    allow(blob).to receive(:variant).and_return(variant)

    service = described_class.new(media, :crop, x: 1, y: 2, width: 10, height: 20)

    result = service.call

    expect(result[:success]).to eq(true)
    expect(result[:data][:variant_url]).to eq('/rails/variant')
  end

  it 'returns error for invalid crop dimensions' do
    service = described_class.new(media, :crop, width: 0, height: 10)

    expect(service.call).to eq(success: false, error: 'Invalid crop dimensions')
  end

  it 'rotates and flips images' do
    variant = instance_double(ActiveStorage::Variant)
    allow(blob).to receive(:variant).and_return(variant)

    rotate_result = described_class.new(media, :rotate, degrees: 90).call
    flip_result = described_class.new(media, :flip, direction: 'horizontal').call

    expect(rotate_result[:success]).to eq(true)
    expect(flip_result[:success]).to eq(true)
  end

  it 'returns error for invalid rotate or flip inputs' do
    rotate_result = described_class.new(media, :rotate, degrees: 45).call
    flip_result = described_class.new(media, :flip, direction: 'diagonal').call

    expect(rotate_result).to eq(success: false, error: 'Invalid rotation degrees')
    expect(flip_result).to eq(success: false, error: 'Invalid flip direction')
  end

  it 'saves edited image as new blob' do
    variant = instance_double(ActiveStorage::Variant)
    processed = instance_double(ActiveStorage::VariantWithRecord, download: 'binary')
    allow(variant).to receive(:processed).and_return(processed)
    allow(blob).to receive(:variant).and_return(variant)

    new_blob = instance_double(
      ActiveStorage::Blob,
      filename: 'new.jpg',
      content_type: 'image/jpeg',
      byte_size: 10,
      metadata: { width: 100, height: 80 },
      analyze: true
    )

    new_metadata = instance_double(MediaMetadata, id: 99, update: true)

    allow(ActiveStorage::Blob).to receive(:create_and_upload!).and_return(new_blob)
    allow(MediaMetadata).to receive(:create!).and_return(new_metadata)

    result = described_class.new(media, :crop, x: 0, y: 0, width: 10, height: 10, save_as_new: true).call

    expect(result[:success]).to eq(true)
    expect(result[:data][:id]).to eq(99)
  end

  it 'handles unexpected errors' do
    allow(blob).to receive(:variant).and_raise(StandardError, 'boom')

    result = described_class.new(media, :crop, x: 0, y: 0, width: 10, height: 10).call

    expect(result[:success]).to eq(false)
    expect(result[:error]).to include('boom')
  end
end
