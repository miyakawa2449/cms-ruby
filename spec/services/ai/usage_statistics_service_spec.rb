require 'rails_helper'

RSpec.describe Ai::UsageStatisticsService do
  include ActiveSupport::Testing::TimeHelpers

  before do
    AiUsageStat.delete_all
    AiGeneration.delete_all
  end

  describe '.daily_usage' do
    it 'aggregates usage per date' do
      date = Date.current
      create(:ai_usage_stat, date: date, total_requests: 3, total_tokens: 30, total_cost: 0.3)
      create(:ai_usage_stat, :sonnet, date: date, total_requests: 2, total_tokens: 20, total_cost: 0.2)

      stats = described_class.daily_usage(date, date)

      expect(stats).to eq([
        {
          date: date,
          requests: 5,
          tokens: 50,
          cost: 0.5
        }
      ])
    end
  end

  describe '.monthly_usage' do
    it 'returns totals with daily and model breakdowns' do
      date = Date.new(2026, 1, 15)
      create(:ai_usage_stat, date: date, total_requests: 4, total_tokens: 40, total_cost: 0.4)
      create(:ai_usage_stat, :sonnet, date: date, total_requests: 1, total_tokens: 10, total_cost: 0.2)

      result = described_class.monthly_usage(2026, 1)

      expect(result[:total_requests]).to eq(5)
      expect(result[:total_tokens]).to eq(50)
      expect(result[:total_cost]).to eq(0.6)
      expect(result[:daily_breakdown]).not_to be_empty
      expect(result[:model_breakdown].map { |row| row[:model] }).to include(
        'anthropic.claude-3-haiku-20240307-v1:0',
        'anthropic.claude-3-5-sonnet-20241022-v2:0'
      )
    end
  end

  describe '.usage_by_feature' do
    it 'aggregates completed generations by feature' do
      create(:ai_generation, :completed, generation_type: 'summary', tokens_used: 100, cost: 0.1)
      create(:ai_generation, :completed, generation_type: 'summary', tokens_used: 200, cost: 0.2)
      create(:ai_generation, :completed, generation_type: 'tags', tokens_used: 50, cost: 0.05)
      create(:ai_generation, generation_type: 'title')

      result = described_class.usage_by_feature(1.day.ago.to_date, Date.current)

      summary_row = result.find { |row| row[:feature] == 'summary' }
      tags_row = result.find { |row| row[:feature] == 'tags' }

      expect(summary_row[:count]).to eq(2)
      expect(summary_row[:tokens]).to eq(300)
      expect(summary_row[:cost]).to eq(0.3)
      expect(summary_row[:feature_label]).to eq('要約生成')
      expect(tags_row[:count]).to eq(1)
    end
  end

  describe '.total_cost' do
    it 'sums cost for date range' do
      create(:ai_usage_stat, date: Date.current, total_cost: 1.23456)

      result = described_class.total_cost(Date.current, Date.current)

      expect(result).to eq(1.23)
    end
  end

  describe '.top_features' do
    it 'returns top features limited by count' do
      create(:ai_generation, :completed, generation_type: 'summary', tokens_used: 100, cost: 0.1)
      create(:ai_generation, :completed, generation_type: 'tags', tokens_used: 50, cost: 0.05)

      result = described_class.top_features(1)

      expect(result.size).to eq(1)
    end
  end

  describe '.export_data' do
    it 'exports CSV with generation details' do
      travel_to Time.zone.local(2026, 1, 20, 10, 30, 0) do
        article = create(:article, title: 'Exported Article')
        create(
          :ai_generation,
          :completed,
          article: article,
          generation_type: 'title',
          model_used: 'model-id',
          tokens_used: 123,
          cost: 0.456789
        )

        csv = described_class.export_data(Date.current, Date.current)

        expect(csv).to include('機能')
        expect(csv).to include('タイトル提案')
        expect(csv).to include('Exported Article')
        expect(csv).to include('model-id')
      end
    end
  end

  describe '.dashboard_summary' do
    it 'returns summary with trends and recent generations' do
      travel_to Date.new(2026, 1, 20) do
        create(:ai_usage_stat, date: Date.current, total_requests: 2, total_tokens: 20, total_cost: 0.2)
        create(:ai_usage_stat, date: 1.month.ago.to_date, total_requests: 1, total_tokens: 10, total_cost: 0.1)
        create(:ai_generation, :completed)

        summary = described_class.dashboard_summary

        expect(summary[:today][:requests]).to eq(2)
        expect(summary[:this_month][:cost]).to eq(0.2)
        expect(summary[:last_month][:cost]).to eq(0.1)
        expect(summary[:trends][:cost]).to be_a(Float)
        expect(summary[:recent_generations]).not_to be_empty
      end
    end
  end

  describe '.chart_data' do
    it 'fills missing dates with zeros' do
      travel_to Date.new(2026, 1, 5) do
        create(:ai_usage_stat, date: 2.days.ago.to_date, total_requests: 1, total_tokens: 10, total_cost: 0.1)
        create(:ai_usage_stat, date: Date.current, total_requests: 2, total_tokens: 20, total_cost: 0.2)

        data = described_class.chart_data(days: 2)

        expect(data[:labels].size).to eq(3)
        expect(data[:datasets][:requests]).to include(0)
      end
    end
  end

  # S1-7 P1-5: UsageTrackerから移設した期間サマリー系
  describe '.summary' do
    before do
      create(:ai_usage_stat, date: Date.current, ai_model: 'model1', total_requests: 10, total_tokens: 1000, total_cost: 0.10)
      create(:ai_usage_stat, date: Date.yesterday, ai_model: 'model1', total_requests: 5, total_tokens: 500, total_cost: 0.05)
      create(:ai_usage_stat, date: Date.current, ai_model: 'model2', total_requests: 3, total_tokens: 300, total_cost: 0.03)
    end

    it '期間の合計を返す' do
      result = described_class.summary(start_date: 7.days.ago.to_date)

      expect(result[:totals][:requests]).to eq(18)
      expect(result[:totals][:tokens]).to eq(1800)
      expect(result[:totals][:cost]).to eq(0.18)
    end

    it 'モデル別の内訳を返す' do
      result = described_class.summary(start_date: 7.days.ago.to_date)

      expect(result[:by_model]).to be_an(Array)
      expect(result[:by_model].length).to eq(2)
    end

    it '日別の内訳を返す' do
      result = described_class.summary(start_date: 7.days.ago.to_date)

      expect(result[:by_date]).to be_an(Array)
      expect(result[:by_date].first[:date]).to eq(Date.current)
    end
  end

  describe '.today' do
    before do
      create(:ai_usage_stat, date: Date.current, ai_model: 'model1', total_requests: 10, total_tokens: 1000, total_cost: 0.10)
      create(:ai_usage_stat, date: Date.current, ai_model: 'model2', total_requests: 5, total_tokens: 500, total_cost: 0.05)
    end

    it '今日の合計を返す' do
      result = described_class.today

      expect(result[:date]).to eq(Date.current)
      expect(result[:requests]).to eq(15)
      expect(result[:tokens]).to eq(1500)
      expect(result[:cost]).to eq(0.15)
    end
  end

  describe '.this_month' do
    before do
      create(:ai_usage_stat, date: Date.current, ai_model: 'model1', total_requests: 10, total_cost: 1.00)
      create(:ai_usage_stat, date: Date.current.beginning_of_month, ai_model: 'model1', total_requests: 5, total_cost: 0.50)
    end

    it '今月の合計を返す' do
      result = described_class.this_month

      expect(result[:totals][:requests]).to eq(15)
      expect(result[:totals][:cost]).to eq(1.50)
    end
  end
end
