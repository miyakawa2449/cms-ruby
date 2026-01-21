# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Media::UploadService do
  let(:valid_image) do
    fixture_file_upload('spec/fixtures/files/test_image.jpg', 'image/jpeg')
  end

  let(:invalid_file) do
    fixture_file_upload('spec/fixtures/files/test.txt', 'text/plain')
  end

  describe '#call' do
    context '正常系' do
      it '画像ファイルをアップロードする' do
        service = described_class.new([ valid_image ])

        result = service.call

        expect(result[:uploaded].count).to eq(1)
        expect(result[:uploaded].first[:status]).to eq('success')
      end

      it 'MediaMetadataレコードを作成する' do
        service = described_class.new([ valid_image ])

        expect {
          service.call
        }.to change(MediaMetadata, :count).by(1)
      end

      it '画像サイズを取得して保存する' do
        service = described_class.new([ valid_image ])

        service.call

        metadata = MediaMetadata.last
        expect(metadata.width).to be > 0
        expect(metadata.height).to be > 0
      end

      it '複数ファイルを同時にアップロードできる' do
        image2 = fixture_file_upload('spec/fixtures/files/test_image.jpg', 'image/jpeg')
        service = described_class.new([ valid_image, image2 ])

        result = service.call

        expect(result[:uploaded].count).to eq(2)
      end
    end

    context '異常系' do
      it '不正なファイル形式を拒否する' do
        service = described_class.new([ invalid_file ])

        result = service.call

        expect(result[:failed].count).to eq(1)
        expect(result[:failed].first[:error]).to include('Invalid file type')
      end

      it 'ファイルサイズ超過を拒否する' do
        # 10MB超のファイルをモック
        allow(valid_image).to receive(:size).and_return(11.megabytes)
        service = described_class.new([ valid_image ])

        result = service.call

        expect(result[:failed].count).to eq(1)
        expect(result[:failed].first[:error]).to include('File size exceeds limit')
      end
    end
  end

  describe 'dimension extraction' do
    let(:service) { described_class.new([]) }

    it 'extracts PNG dimensions' do
      png = ("\x89PNG\r\n\x1A\n" + ("\x00" * 8) + [1, 2].pack("N2") + ("\x00" * 4)).b
      blob = instance_double(ActiveStorage::Blob, metadata: {}, download: png)

      width, height = service.send(:extract_dimensions, blob)

      expect([width, height]).to eq([1, 2])
    end

    it 'extracts GIF dimensions' do
      gif = "GIF89a" + [3, 4].pack("v2") + ("\x00" * 4)
      blob = instance_double(ActiveStorage::Blob, metadata: {}, download: gif)

      width, height = service.send(:extract_dimensions, blob)

      expect([width, height]).to eq([3, 4])
    end

    it 'returns nil dimensions for unknown data' do
      blob = instance_double(ActiveStorage::Blob, metadata: {}, download: "xxxx")

      width, height = service.send(:extract_dimensions, blob)

      expect([width, height]).to eq([nil, nil])
    end

    it 'returns nil dimensions when download fails' do
      blob = instance_double(ActiveStorage::Blob, metadata: {})
      allow(blob).to receive(:download).and_raise(StandardError, "fail")

      width, height = service.send(:extract_dimensions, blob)

      expect([width, height]).to eq([nil, nil])
    end
  end
end
