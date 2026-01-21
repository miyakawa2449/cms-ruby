require 'rails_helper'

RSpec.describe OgpFetcherService do
  let(:url) { 'https://example.com/page' }
  let(:html) do
    <<~HTML
      <html>
        <head>
          <title>Sample Title</title>
          <meta property="og:title" content="OG Title" />
          <meta property="og:description" content="#{'a' * 210}" />
          <meta property="og:image" content="/images/og.png" />
          <meta property="og:site_name" content="Example Site" />
          <link rel="icon" href="/favicon.png" />
        </head>
        <body></body>
      </html>
    HTML
  end

  before do
    Rails.cache.clear
  end

  it 'fetches and caches OGP data' do
    stub_request(:get, url).to_return(status: 200, body: html)

    result = described_class.new(url).fetch
    cached = described_class.new(url).fetch

    expect(result.success?).to eq(true)
    expect(result.data.title).to eq('OG Title')
    expect(result.data.description.length).to eq(OgpFetcherService::MAX_DESCRIPTION_LENGTH)
    expect(result.data.image).to eq('https://example.com/images/og.png')
    expect(result.data.favicon).to eq('https://example.com/favicon.png')
    expect(cached.success?).to eq(true)

    expect(a_request(:get, url)).to have_been_made.at_least_once
  end

  it 'returns error when fetch fails' do
    stub_request(:get, url).to_timeout

    result = described_class.new(url).fetch

    expect(result.success?).to eq(false)
    expect(result.error).to be_present
  end

  it 'falls back to host title when missing metadata' do
    minimal_html = '<html><head></head><body></body></html>'
    stub_request(:get, url).to_return(status: 200, body: minimal_html)

    result = described_class.new(url).fetch

    expect(result.success?).to eq(true)
    expect(result.data.title).to eq('example.com')
    expect(result.data.site_name).to eq('example.com')
  end
end
