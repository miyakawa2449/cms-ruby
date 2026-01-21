require 'rails_helper'

RSpec.describe SiteAssetsService do
  let(:request) do
    instance_double(ActionDispatch::Request, host: 'example.com', port: 3000, protocol: 'http://', base_url: 'http://example.com')
  end

  it 'renders fallback logo when no attachment' do
    logo_setting = instance_double(SiteSetting, image_value: instance_double(ActiveStorage::Attached::One, attached?: false))
    allow(SiteSetting).to receive(:logo).and_return(logo_setting)

    html = described_class.new.site_logo

    expect(html).to include('M')
  end

  it 'renders logo image when attachment exists' do
    attachment = instance_double(ActiveStorage::Attached::One, attached?: true)
    logo_setting = instance_double(SiteSetting, image_value: attachment)
    allow(SiteSetting).to receive(:logo).and_return(logo_setting)
    allow(Rails.application.routes.url_helpers).to receive(:rails_storage_proxy_path).and_return('/logo.png')

    html = described_class.new.site_logo(class: 'h-8', alt: 'Logo')

    expect(html).to include('img')
    expect(html).to include('Logo')
  end

  it 'renders favicon tags' do
    attachment = instance_double(ActiveStorage::Attached::One, attached?: true)
    favicon_setting = instance_double(SiteSetting, image_value: attachment)
    allow(SiteSetting).to receive(:favicon).and_return(favicon_setting)
    allow(Rails.application.routes.url_helpers).to receive(:rails_blob_path).and_return('/favicon.png')

    html = described_class.new.favicon_tags

    expect(html).to include('favicon.png')
    expect(html).to include('apple-touch-icon')
  end

  it 'returns default og image url when not attached' do
    og_setting = instance_double(SiteSetting, image_value: instance_double(ActiveStorage::Attached::One, attached?: false))
    allow(SiteSetting).to receive(:og_image).and_return(og_setting)

    url = described_class.new(request).og_image_url

    expect(url).to include('og-default.jpg')
  end

  it 'generates safe url for attachments with fallback' do
    attachment = instance_double(ActiveStorage::Attached::One, attached?: true)
    allow(Rails.application.routes.url_helpers).to receive(:url_for).and_raise(StandardError, 'boom')

    url = described_class.new.safe_url_for(attachment)

    expect(url).to eq('/images/default.jpg')
  end
end
