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
end
