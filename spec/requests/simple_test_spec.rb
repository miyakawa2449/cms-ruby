require 'rails_helper'

RSpec.describe 'SimpleTest', type: :request do
  it 'returns test items summary' do
    TestItem.create!(name: 'Item A')
    TestItem.create!(name: 'Item B')

    get '/test'

    expect(response).to have_http_status(:success)
    expect(response.body).to include('Test Items Count: 2')
    expect(response.body).to include('Item A')
  end

  it 'renders error details when exception occurs' do
    allow(TestItem).to receive(:all).and_raise(StandardError, 'boom')

    get '/test'

    expect(response).to have_http_status(:success)
    expect(response.body).to include('Error occurred')
    expect(response.body).to include('boom')
  end
end
