require 'rails_helper'

RSpec.describe Ai::UsageTracker do
  describe '.track' do
    let(:model_id) { 'anthropic.claude-3-haiku-20240307-v1:0' }

    it '新しいAiUsageStatを作成する' do
      expect {
        described_class.track(
          model_id: model_id,
          generation_type: :summary,
          tokens: 100,
          cost: 0.01
        )
      }.to change(AiUsageStat, :count).by(1)
    end

    it '既存のAiUsageStatを更新する' do
      # Create existing stat with specific values
      AiUsageStat.create!(
        date: Date.current,
        ai_model: model_id,
        total_requests: 5,
        total_tokens: 500,
        total_cost: 0.05
      )

      expect {
        described_class.track(
          model_id: model_id,
          generation_type: :summary,
          tokens: 100,
          cost: 0.01
        )
      }.not_to change(AiUsageStat, :count)

      stat = AiUsageStat.find_by!(date: Date.current, ai_model: model_id)
      expect(stat.total_requests).to eq(6)
      expect(stat.total_tokens).to eq(600)
    end

    it 'エラーが発生しても例外を投げない' do
      allow(AiUsageStat).to receive(:for_today).and_raise(StandardError, 'DB Error')

      expect {
        described_class.track(
          model_id: model_id,
          generation_type: :summary,
          tokens: 100,
          cost: 0.01
        )
      }.not_to raise_error
    end
  end

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

  describe '.monthly_limit_exceeded?' do
    before do
      create(:ai_usage_stat, date: Date.current, ai_model: 'model1', total_cost: 10.00)
    end

    it '上限を超えている場合trueを返す' do
      expect(described_class.monthly_limit_exceeded?(5.00)).to be true
    end

    it '上限を超えていない場合falseを返す' do
      expect(described_class.monthly_limit_exceeded?(20.00)).to be false
    end
  end

  describe '.remaining_budget' do
    before do
      create(:ai_usage_stat, date: Date.current, ai_model: 'model1', total_cost: 10.00)
    end

    it '残り予算を返す' do
      expect(described_class.remaining_budget(50.00)).to eq(40.00)
    end

    it '予算超過の場合0を返す' do
      expect(described_class.remaining_budget(5.00)).to eq(0)
    end
  end
end
