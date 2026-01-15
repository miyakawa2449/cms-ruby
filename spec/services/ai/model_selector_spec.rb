require 'rails_helper'

RSpec.describe Ai::ModelSelector do
  describe '.select' do
    it 'summaryに対してSonnetモデルを返す' do
      expect(described_class.select(:summary)).to include('claude-3-5-sonnet')
    end

    it 'tagsに対してHaikuモデルを返す' do
      expect(described_class.select(:tags)).to include('claude-3-haiku')
    end

    it 'slugに対してHaikuモデルを返す' do
      expect(described_class.select(:slug)).to include('claude-3-haiku')
    end

    it 'seo_metaに対してSonnetモデルを返す' do
      expect(described_class.select(:seo_meta)).to include('claude-3-5-sonnet')
    end

    it 'structureに対してSonnetモデルを返す' do
      expect(described_class.select(:structure)).to include('claude-3-5-sonnet')
    end

    it '不明なタイプに対してsummaryのモデルを返す' do
      expect(described_class.select(:unknown)).to include('claude-3-5-sonnet')
    end
  end

  describe '.calculate_cost' do
    let(:sonnet_model) { 'anthropic.claude-3-5-sonnet-20241022-v2:0' }
    let(:haiku_model) { 'anthropic.claude-3-haiku-20240307-v1:0' }

    it 'Sonnetモデルのコストを計算する' do
      # 1000 input tokens * $3/1M + 500 output tokens * $15/1M
      # = 0.003 + 0.0075 = 0.0105
      cost = described_class.calculate_cost(sonnet_model, 1000, 500)
      expect(cost).to eq(0.0105)
    end

    it 'Haikuモデルのコストを計算する' do
      # 1000 input tokens * $0.25/1M + 500 output tokens * $1.25/1M
      # = 0.00025 + 0.000625 = 0.000875
      cost = described_class.calculate_cost(haiku_model, 1000, 500)
      expect(cost).to eq(0.000875)
    end

    it '不明なモデルに対して0を返す' do
      cost = described_class.calculate_cost('unknown-model', 1000, 500)
      expect(cost).to eq(0)
    end
  end

  describe '.display_name' do
    it 'Sonnetモデルの表示名を返す' do
      expect(described_class.display_name('anthropic.claude-3-5-sonnet-20241022-v2:0')).to eq('Claude 3.5 Sonnet')
    end

    it 'Haikuモデルの表示名を返す' do
      expect(described_class.display_name('anthropic.claude-3-haiku-20240307-v1:0')).to eq('Claude 3 Haiku')
    end

    it '不明なモデルはそのまま返す' do
      expect(described_class.display_name('unknown-model')).to eq('unknown-model')
    end
  end

  describe '.available?' do
    it '既知のモデルに対してtrueを返す' do
      expect(described_class.available?('anthropic.claude-3-5-sonnet-20241022-v2:0')).to be true
      expect(described_class.available?('anthropic.claude-3-haiku-20240307-v1:0')).to be true
    end

    it '不明なモデルに対してfalseを返す' do
      expect(described_class.available?('unknown-model')).to be false
    end
  end
end
