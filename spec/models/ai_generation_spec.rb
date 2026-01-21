require 'rails_helper'

RSpec.describe AiGeneration, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:generation_type) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_inclusion_of(:generation_type).in_array(AiGeneration::GENERATION_TYPES) }
    it { is_expected.to validate_inclusion_of(:status).in_array(AiGeneration::STATUSES) }
    it { is_expected.to validate_numericality_of(:tokens_used).only_integer.is_greater_than_or_equal_to(0).allow_nil }
    it { is_expected.to validate_numericality_of(:cost).is_greater_than_or_equal_to(0).allow_nil }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:article).optional }
    it { is_expected.to belong_to(:admin_user).optional }
  end

  describe 'scopes' do
    let!(:completed_generation) { create(:ai_generation, :completed) }
    let!(:failed_generation) { create(:ai_generation, :failed) }
    let!(:pending_generation) { create(:ai_generation) }
    let!(:summary_generation) { create(:ai_generation, :summary, :completed) }
    let!(:tags_generation) { create(:ai_generation, :tags, :completed) }

    describe '.completed' do
      it 'returns only completed generations' do
        expect(described_class.completed).to include(completed_generation, summary_generation, tags_generation)
        expect(described_class.completed).not_to include(failed_generation, pending_generation)
      end
    end

    describe '.failed' do
      it 'returns only failed generations' do
        expect(described_class.failed).to include(failed_generation)
        expect(described_class.failed).not_to include(completed_generation, pending_generation)
      end
    end

    describe '.pending' do
      it 'returns only pending generations' do
        expect(described_class.pending).to include(pending_generation)
        expect(described_class.pending).not_to include(completed_generation, failed_generation)
      end
    end

    describe '.by_type' do
      it 'returns generations of specified type' do
        expect(described_class.by_type('tags')).to include(tags_generation)
        expect(described_class.by_type('tags')).not_to include(summary_generation)
      end
    end
  end

  describe '#complete!' do
    let(:generation) { create(:ai_generation, status: 'pending') }
    let(:output_data) { { summaries: [ 'テスト要約' ] } }

    it 'updates status to completed' do
      generation.complete!(output_data, tokens: 500, cost: 0.005)
      expect(generation.reload.status).to eq('completed')
    end

    it 'stores output data' do
      generation.complete!(output_data, tokens: 500, cost: 0.005)
      expect(generation.reload.output_data).to eq(output_data.stringify_keys)
    end

    it 'stores tokens and cost' do
      generation.complete!(output_data, tokens: 500, cost: 0.005)
      expect(generation.reload.tokens_used).to eq(500)
      expect(generation.reload.cost).to eq(0.005)
    end
  end

  describe '#fail!' do
    let(:generation) { create(:ai_generation, status: 'pending') }

    it 'updates status to failed' do
      generation.fail!('API Error occurred')
      expect(generation.reload.status).to eq('failed')
    end

    it 'stores error message' do
      generation.fail!('API Error occurred')
      expect(generation.reload.error_message).to eq('API Error occurred')
    end
  end

  describe 'status helpers' do
    describe '#completed?' do
      it 'returns true when status is completed' do
        generation = build(:ai_generation, :completed)
        expect(generation.completed?).to be true
      end

      it 'returns false when status is not completed' do
        generation = build(:ai_generation, :failed)
        expect(generation.completed?).to be false
      end
    end

    describe '#failed?' do
      it 'returns true when status is failed' do
        generation = build(:ai_generation, :failed)
        expect(generation.failed?).to be true
      end
    end

    describe '#pending?' do
      it 'returns true when status is pending' do
        generation = build(:ai_generation)
        expect(generation.pending?).to be true
      end
    end
  end

  describe '#formatted_cost' do
    it 'formats cost with 4 decimal places' do
      generation = build(:ai_generation, cost: 0.0123)
      expect(generation.formatted_cost).to eq('$0.0123')
    end

    it 'handles nil cost' do
      generation = build(:ai_generation, cost: nil)
      expect(generation.formatted_cost).to eq('$0.0000')
    end
  end

  describe '.total_cost_for' do
    let!(:old_generation) { create(:ai_generation, :completed, cost: 0.1, created_at: 10.days.ago) }
    let!(:recent_generation) { create(:ai_generation, :completed, cost: 0.2, created_at: 2.days.ago) }
    let!(:today_generation) { create(:ai_generation, :completed, cost: 0.3, created_at: Time.current) }
    let!(:failed_generation) { create(:ai_generation, :failed, cost: 0.5, created_at: 1.day.ago) }

    it 'sums cost for completed generations in date range' do
      total = described_class.total_cost_for(5.days.ago.to_date)
      expect(total).to be_within(0.01).of(0.5) # recent + today, not failed
    end

    it 'excludes failed generations' do
      total = described_class.total_cost_for(5.days.ago.to_date)
      expect(total).not_to eq(1.0)
    end
  end
end
