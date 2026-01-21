require 'rails_helper'

RSpec.describe SiteSettingValueManager do
  before do
    SiteSetting.delete_all
  end

  describe 'text settings' do
    it 'gets and updates values' do
      setting = SiteSetting.create!(key: 'site_title', setting_type: 'text', description: 'Title', value: 'Old')
      manager = described_class.new(setting)

      expect(manager.get_value).to eq('Old')

      manager.set_value('New')
      expect(setting.reload.value).to eq('New')
    end

    it 'validates updates' do
      setting = SiteSetting.create!(key: 'site_title', setting_type: 'text', description: 'Title', value: 'Old')
      manager = described_class.new(setting)

      result = manager.update_value('')

      expect(result[:valid]).to eq(false)
      expect(result[:errors]).not_to be_empty
    end

    it 'restores default values' do
      setting = SiteSetting.create!(key: 'site_title', setting_type: 'text', description: 'Title', value: 'Old')
      manager = described_class.new(setting)

      expect(manager.restore_default).to eq(true)
      expect(setting.reload.value).to eq(SiteSettingTypeManager.setting_default(:site_title))
    end
  end

  describe 'image settings' do
    it 'returns formatted values and urls' do
      setting = SiteSetting.create!(key: 'logo', setting_type: 'image', description: 'Logo')
      attachment = double(
        'Attachment',
        attached?: true,
        filename: double(to_s: 'logo.png'),
        byte_size: 123,
        content_type: 'image/png'
      )

      allow(setting).to receive(:image_value).and_return(attachment)
      allow(Rails.application.routes.url_helpers).to receive(:rails_blob_path).and_return('/rails/blob')

      manager = described_class.new(setting)

      expect(manager.has_value?).to eq(true)
      expect(manager.formatted_value[:filename]).to eq('logo.png')
      expect(manager.image_url).to eq('/rails/blob')
    end
  end

  describe 'file settings' do
    it 'generates download url safely' do
      setting = SiteSetting.create!(key: 'download', setting_type: 'file', description: 'File')
      attachment = instance_double(ActiveStorage::Attached::One, attached?: true)
      allow(setting).to receive(:file_value).and_return(attachment)
      allow(Rails.application.routes.url_helpers).to receive(:rails_blob_path).and_return('/rails/file')

      manager = described_class.new(setting)

      expect(manager.download_url).to eq('/rails/file')
    end
  end
end
