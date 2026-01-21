require 'rails_helper'

RSpec.describe MetaTagsService do
  let(:assets_service) do
    instance_double(SiteAssetsService, favicon_tags: '<link>', og_image_url: '/og.jpg', safe_url_for: '/safe')
  end

  before do
    allow(SiteAssetsService).to receive(:new).and_return(assets_service)
    allow(SiteSetting).to receive(:site_title).and_return(double(value: 'Site Title'))
    allow(SiteSetting).to receive(:site_description).and_return(double(value: 'Site Description'))
  end

  it 'builds article meta tags' do
    article = create(:article, :published, meta_description: nil)

    html = described_class.new.article_meta_tags(article)

    expect(html).to include('og:title')
    expect(html).to include(article.title)
    expect(html).to include('/og.jpg')
  end

  it 'builds portfolio meta tags' do
    html = described_class.new.portfolio_meta_tags

    expect(html).to include('Site Title')
    expect(html).to include('twitter:card')
  end

  it 'builds category meta tags with fallback' do
    category = create(:category, name: 'Tech', description: nil)

    html = described_class.new.category_meta_tags(category)

    expect(html).to include('Tech')
  end

  it 'builds my story meta tags' do
    html = described_class.new.my_story_meta_tags('Story', 'Desc')

    expect(html).to include('Story')
    expect(html).to include('Desc')
  end
end
