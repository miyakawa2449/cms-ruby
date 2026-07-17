require 'rails_helper'

RSpec.describe Ai::UsageTracker do
  before do
    AiUsageStat.delete_all
  end

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

  # 集計系（summary/today/this_month）のspecはS1-7 P1-5で
  # spec/services/ai/usage_statistics_service_spec.rb へ移設。
  # monthly_limit_exceeded?/remaining_budget は呼び出しゼロのため実装ごと削除
end
