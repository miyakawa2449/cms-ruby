require 'rails_helper'

RSpec.describe NavigationHelper, type: :helper do
  it 'builds breadcrumb html' do
    html = helper.breadcrumbs({ text: 'Home', url: '/' }, { text: 'Current' })

    expect(html).to include('Home')
    expect(html).to include('Current')
  end

  it 'detects current page and builds classes' do
    allow(helper).to receive(:request).and_return(double(path: '/blog'))

    expect(helper.current_page?('/blog')).to eq(true)
    expect(helper.nav_link_class('/blog')).to include('text-blue-600')
    expect(helper.nav_link_class('/about')).to include('text-gray-700')
  end

  it 'builds page title with site setting' do
    setting = instance_double(SiteSetting, get_value: 'Site Name')
    allow(SiteSetting).to receive(:site_title).and_return(setting)

    expect(helper.page_title('Title')).to eq('Title | Site Name')
    expect(helper.page_title).to eq('Site Name')
  end

  it 'renders category navigation' do
    category = create(:category, slug: 'tech')
    article = create(:article, :published)
    article.categories << category

    html = helper.category_navigation

    expect(html).to include('すべて')
    expect(html).to include(category.name)
  end

  it 'renders tag cloud' do
    tag1 = create(:tag, article_count: 5)
    tag2 = create(:tag, article_count: 1)
    tags = Tag.where(id: [tag1.id, tag2.id])

    html = helper.tag_cloud(tags)

    expect(html).to include("##{tag1.name}")
    expect(html).to include('text-lg')
  end
end
