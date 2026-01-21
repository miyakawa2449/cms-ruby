require 'rails_helper'

RSpec.describe 'Admin::SiteSettings', type: :request do
  let(:admin_user) { create(:admin_user) }
  let(:value_manager) { instance_double(SiteSettingValueManager, update_value: { valid: true }) }
  let(:attachment) { instance_double(ActiveStorage::Attached::One, attached?: false) }
  let(:setting) { instance_double(SiteSetting, value_manager: value_manager, image_value: attachment, value: '') }

  before do
    sign_in admin_user, scope: :admin_user
    allow(SiteSetting).to receive(:favicon).and_return(setting)
    allow(SiteSetting).to receive(:logo).and_return(setting)
    allow(SiteSetting).to receive(:site_title).and_return(setting)
    allow(SiteSetting).to receive(:site_description).and_return(setting)
    allow(SiteSetting).to receive(:og_image).and_return(setting)
    allow(SiteSetting).to receive(:gtm_id).and_return(setting)
  end

  it 'renders show page' do
    get admin_site_settings_path

    expect(response).to have_http_status(:success)
  end

  it 'updates site settings' do
    patch admin_site_settings_path, params: {
      site_setting: {
        favicon: 'file',
        logo: 'file',
        og_image: 'file',
        site_title: 'Title',
        site_description: 'Desc',
        gtm_id: 'GTM-1'
      }
    }

    expect(response).to redirect_to(admin_site_settings_path)
  end

  it 'redirects with alert when no updates' do
    patch admin_site_settings_path, params: { site_setting: {} }

    expect(response).to redirect_to(admin_site_settings_path)
  end
end
