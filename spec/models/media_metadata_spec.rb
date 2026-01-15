# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MediaMetadata, type: :model do
  describe 'associations' do
    it { should belong_to(:blob).class_name('ActiveStorage::Blob') }
  end

  describe 'validations' do
    it { should validate_presence_of(:blob) }
  end

  describe 'scopes' do
    before do
      MediaMetadata.destroy_all
    end

    let!(:old_media) { create(:media_metadata, created_at: 2.days.ago) }
    let!(:used_media) { create(:media_metadata, usage_count: 3, created_at: 1.day.ago) }
    let!(:unused_media) { create(:media_metadata, usage_count: 0, created_at: 1.day.ago) }
    let!(:new_media) { create(:media_metadata, created_at: 1.hour.ago) }

    describe '.used' do
      it '使用中の画像のみを返す' do
        expect(MediaMetadata.used).to include(used_media)
        expect(MediaMetadata.used).not_to include(unused_media)
      end
    end

    describe '.unused' do
      it '未使用の画像のみを返す' do
        expect(MediaMetadata.unused).to include(unused_media)
        expect(MediaMetadata.unused).not_to include(used_media)
      end
    end

    describe '.recent' do
      it '新しい順に並ぶ' do
        expect(MediaMetadata.recent.first).to eq(new_media)
        expect(MediaMetadata.recent.last).to eq(old_media)
      end
    end
  end

  describe '#track_usage' do
    let(:metadata) { create(:media_metadata, usage_count: 0) }

    it '使用状況カウントをインクリメントする' do
      expect {
        metadata.track_usage
      }.to change { metadata.reload.usage_count }.by(1)
    end

    it '複数回呼び出すと正しくカウントされる' do
      metadata.track_usage
      metadata.track_usage

      expect(metadata.reload.usage_count).to eq(2)
    end
  end

  describe '#untrack_usage' do
    let(:metadata) { create(:media_metadata, usage_count: 2) }

    it '使用状況カウントをデクリメントする' do
      expect {
        metadata.untrack_usage
      }.to change { metadata.reload.usage_count }.by(-1)
    end

    it 'カウントが0以下にならない' do
      metadata.update(usage_count: 0)

      metadata.untrack_usage

      expect(metadata.reload.usage_count).to eq(0)
    end
  end

  describe '#used?' do
    it '使用中の場合trueを返す' do
      metadata = create(:media_metadata, usage_count: 1)
      expect(metadata.used?).to be true
    end

    it '未使用の場合falseを返す' do
      metadata = create(:media_metadata, usage_count: 0)
      expect(metadata.used?).to be false
    end
  end

  describe '#filename' do
    it 'blobのファイル名を返す' do
      blob = create(:active_storage_blob, filename: 'test_image.jpg')
      metadata = create(:media_metadata, blob: blob)

      expect(metadata.filename).to eq('test_image.jpg')
    end
  end

  describe '#url' do
    it 'blobのURLを返す' do
      metadata = create(:media_metadata)
      expect(metadata.url).to be_present
    end
  end

  describe '#human_file_size' do
    it 'ファイルサイズを人間が読める形式で返す' do
      metadata = create(:media_metadata, file_size: 2_457_600)
      expect(metadata.human_file_size).to eq('2.34 MB')
    end
  end

  describe '#dimensions' do
    it '画像サイズを文字列で返す' do
      metadata = create(:media_metadata, width: 1920, height: 1080)
      expect(metadata.dimensions).to eq('1920x1080')
    end

    it 'サイズが不明な場合は「不明」を返す' do
      metadata = create(:media_metadata, width: nil, height: nil)
      expect(metadata.dimensions).to eq('不明')
    end
  end
end
