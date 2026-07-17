require 'rails_helper'

RSpec.describe NavigationHelper, type: :helper do
  describe '#page_title' do
    it 'builds page title with site setting' do
      setting = instance_double(SiteSetting, get_value: 'Site Name')
      allow(SiteSetting).to receive(:site_title).and_return(setting)

      expect(helper.page_title('Title')).to eq('Title | Site Name')
      expect(helper.page_title).to eq('Site Name')
    end

    it 'falls back to the default site title when the setting is missing' do
      allow(SiteSetting).to receive(:site_title).and_return(nil)

      expect(helper.page_title).to eq(SiteSetting.default_for(:site_title))
    end
  end
end
