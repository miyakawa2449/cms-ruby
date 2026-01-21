require 'rails_helper'

RSpec.describe 'Admin::AiUsage', type: :request do
  let(:admin_user) { create(:admin_user) }
  let(:summary) do
    {
      today: { requests: 0, tokens: 0, cost: 0 },
      this_month: { requests: 0, tokens: 0, cost: 0 },
      last_month: { requests: 0, tokens: 0, cost: 0 },
      trends: { cost: 0, requests: 0 },
      top_features: [],
      recent_generations: []
    }
  end

  before do
    sign_in admin_user, scope: :admin_user
    allow(Ai::UsageStatisticsService).to receive(:dashboard_summary).and_return(summary)
    allow(Ai::UsageStatisticsService).to receive(:chart_data).and_return(labels: [], datasets: {})
    allow(Ai::UsageStatisticsService).to receive(:usage_by_feature).and_return([])
    allow(Ai::UsageStatisticsService).to receive(:model_breakdown).and_return([])
  end

  it 'renders index with valid dates' do
    get admin_ai_usage_index_path, params: { start_date: '2026-01-01', end_date: '2026-01-20' }

    expect(response).to have_http_status(:success)
  end

  it 'falls back when dates are invalid' do
    get admin_ai_usage_index_path, params: { start_date: 'bad-date', end_date: 'bad-date' }

    expect(response).to have_http_status(:success)
  end

  it 'exports csv data' do
    allow(Ai::UsageStatisticsService).to receive(:export_data).and_return("col\n")

    get export_admin_ai_usage_index_path, params: { start_date: '2026-01-01', end_date: '2026-01-20' }

    expect(response).to have_http_status(:success)
    expect(response.header['Content-Type']).to include('text/csv')
  end

  it 'redirects when export date is invalid' do
    allow(Ai::UsageStatisticsService).to receive(:export_data).and_return("col\n")

    get export_admin_ai_usage_index_path, params: { start_date: 'bad-date' }

    expect(response).to redirect_to(admin_ai_usage_index_path)
  end
end
