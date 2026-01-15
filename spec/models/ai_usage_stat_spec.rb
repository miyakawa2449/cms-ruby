require 'rails_helper'

RSpec.describe AiUsageStat, type: :model do
  describe 'validations' do
    subject { build(:ai_usage_stat) }

    it { is_expected.to validate_presence_of(:date) }
    it { is_expected.to validate_presence_of(:ai_model) }
    it { is_expected.to validate_uniqueness_of(:date).scoped_to(:ai_model).with_message('and model combination already exists') }
    it { is_expected.to validate_numericality_of(:total_requests).only_integer.is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:total_tokens).only_integer.is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:total_cost).is_greater_than_or_equal_to(0) }
  end

  describe 'scopes' do
    let!(:today_stat) { create(:ai_usage_stat, date: Date.current) }
    let!(:yesterday_stat) { create(:ai_usage_stat, :yesterday, ai_model: 'different-model') }
    let!(:old_stat) { create(:ai_usage_stat, :last_week, ai_model: 'another-model') }

    describe '.for_date' do
      it 'returns stats for specific date' do
        expect(described_class.for_date(Date.current)).to include(today_stat)
        expect(described_class.for_date(Date.current)).not_to include(yesterday_stat)
      end
    end

    describe '.recent' do
      it 'orders by date descending' do
        expect(described_class.recent.first).to eq(today_stat)
      end
    end

    describe '.last_30_days' do
      it 'returns stats from last 30 days' do
        expect(described_class.last_30_days).to include(today_stat, yesterday_stat)
        expect(described_class.last_30_days).to include(old_stat)
      end
    end
  end

  describe '.for_today' do
    context 'when stat exists for today' do
      let!(:existing_stat) { create(:ai_usage_stat, date: Date.current, ai_model: 'test-model') }

      it 'returns existing stat' do
        stat = described_class.for_today('test-model')
        expect(stat).to eq(existing_stat)
      end
    end

    context 'when stat does not exist' do
      it 'returns new unsaved stat' do
        stat = described_class.for_today('new-model')
        expect(stat).to be_new_record
        expect(stat.date).to eq(Date.current)
        expect(stat.ai_model).to eq('new-model')
      end
    end
  end

  describe '#record_usage!' do
    let(:stat) { described_class.for_today('test-model') }

    context 'with new stat' do
      it 'creates new record with usage data' do
        stat.record_usage!(requests: 1, tokens: 100, cost: 0.01, generation_type: 'summary')
        expect(stat).to be_persisted
        expect(stat.total_requests).to eq(1)
        expect(stat.total_tokens).to eq(100)
        expect(stat.total_cost).to eq(0.01)
      end
    end

    context 'with existing stat' do
      let!(:existing_stat) { create(:ai_usage_stat, date: Date.current, ai_model: 'existing-model', total_requests: 5, total_tokens: 500, total_cost: 0.05) }

      it 'increments existing values' do
        existing_stat.record_usage!(requests: 2, tokens: 200, cost: 0.02)
        expect(existing_stat.total_requests).to eq(7)
        expect(existing_stat.total_tokens).to eq(700)
        expect(existing_stat.total_cost).to eq(0.07)
      end
    end

    context 'with generation_type breakdown' do
      it 'updates breakdown data' do
        stat.record_usage!(requests: 1, tokens: 100, cost: 0.01, generation_type: 'summary')
        expect(stat.breakdown['summary']['requests']).to eq(1)
        expect(stat.breakdown['summary']['tokens']).to eq(100)
      end

      it 'accumulates breakdown data' do
        stat.record_usage!(requests: 1, tokens: 100, cost: 0.01, generation_type: 'summary')
        stat.record_usage!(requests: 2, tokens: 200, cost: 0.02, generation_type: 'summary')
        expect(stat.breakdown['summary']['requests']).to eq(3)
        expect(stat.breakdown['summary']['tokens']).to eq(300)
      end
    end
  end

  describe 'class methods for aggregation' do
    let!(:stat1) { create(:ai_usage_stat, date: Date.current, ai_model: 'model1', total_requests: 10, total_tokens: 1000, total_cost: 0.10) }
    let!(:stat2) { create(:ai_usage_stat, date: Date.current, ai_model: 'model2', total_requests: 5, total_tokens: 500, total_cost: 0.05) }
    let!(:old_stat) { create(:ai_usage_stat, date: 10.days.ago.to_date, ai_model: 'model1', total_requests: 20, total_tokens: 2000, total_cost: 0.20) }

    describe '.total_cost_for' do
      it 'sums cost for date range' do
        expect(described_class.total_cost_for(5.days.ago.to_date)).to eq(0.15)
      end
    end

    describe '.total_tokens_for' do
      it 'sums tokens for date range' do
        expect(described_class.total_tokens_for(5.days.ago.to_date)).to eq(1500)
      end
    end

    describe '.total_requests_for' do
      it 'sums requests for date range' do
        expect(described_class.total_requests_for(5.days.ago.to_date)).to eq(15)
      end
    end
  end

  describe 'instance helper methods' do
    let(:stat) { build(:ai_usage_stat, total_requests: 10, total_tokens: 1000, total_cost: 0.10) }

    describe '#formatted_cost' do
      it 'formats cost with dollar sign' do
        expect(stat.formatted_cost).to eq('$0.10')
      end
    end

    describe '#average_cost_per_request' do
      it 'calculates average' do
        expect(stat.average_cost_per_request).to eq(0.01)
      end

      it 'handles zero requests' do
        stat.total_requests = 0
        expect(stat.average_cost_per_request).to eq(0)
      end
    end

    describe '#average_tokens_per_request' do
      it 'calculates average' do
        expect(stat.average_tokens_per_request).to eq(100)
      end

      it 'handles zero requests' do
        stat.total_requests = 0
        expect(stat.average_tokens_per_request).to eq(0)
      end
    end
  end
end
