require 'rails_helper'

RSpec.describe Ai::ModelSelector do
  describe '.select' do
    it 'summaryに対してClaude Sonnet 4.5を返す' do
      expect(described_class.select(:summary)).to eq('us.anthropic.claude-sonnet-4-5-20250929-v1:0')
    end

    it 'titleに対してClaude Sonnet 4.5を返す' do
      expect(described_class.select(:title)).to eq('us.anthropic.claude-sonnet-4-5-20250929-v1:0')
    end

    it 'tagsに対してClaude Haiku 4.5を返す' do
      expect(described_class.select(:tags)).to eq('us.anthropic.claude-haiku-4-5-20251001-v1:0')
    end

    it 'slugに対してClaude Haiku 4.5を返す' do
      expect(described_class.select(:slug)).to eq('us.anthropic.claude-haiku-4-5-20251001-v1:0')
    end

    it 'seo_metaに対してClaude Sonnet 4.5を返す' do
      expect(described_class.select(:seo_meta)).to eq('us.anthropic.claude-sonnet-4-5-20250929-v1:0')
    end

    it 'structureに対してClaude Sonnet 4.5を返す' do
      expect(described_class.select(:structure)).to eq('us.anthropic.claude-sonnet-4-5-20250929-v1:0')
    end

    it '不明なタイプに対してsummaryのモデルを返す' do
      expect(described_class.select(:unknown)).to eq('us.anthropic.claude-sonnet-4-5-20250929-v1:0')
    end
  end

  describe '.calculate_cost' do
    context 'Claude 4.5モデル' do
      let(:sonnet_model) { 'us.anthropic.claude-sonnet-4-5-20250929-v1:0' }
      let(:haiku_model) { 'us.anthropic.claude-haiku-4-5-20251001-v1:0' }

      it 'Sonnet 4.5モデルのコストを計算する' do
        # 1000 input tokens * $3/1M + 500 output tokens * $15/1M
        # = 0.003 + 0.0075 = 0.0105
        cost = described_class.calculate_cost(sonnet_model, 1000, 500)
        expect(cost).to eq(0.0105)
      end

      it 'Haiku 4.5モデルのコストを計算する' do
        # 1000 input tokens * $1/1M + 500 output tokens * $5/1M
        # = 0.001 + 0.0025 = 0.0035
        cost = described_class.calculate_cost(haiku_model, 1000, 500)
        expect(cost).to eq(0.0035)
      end
    end

    context 'Claude 3.5/3モデル（後方互換性）' do
      let(:sonnet_model) { 'anthropic.claude-3-5-sonnet-20241022-v2:0' }
      let(:haiku_model) { 'anthropic.claude-3-haiku-20240307-v1:0' }

      it 'Sonnet 3.5モデルのコストを計算する' do
        cost = described_class.calculate_cost(sonnet_model, 1000, 500)
        expect(cost).to eq(0.0105)
      end

      it 'Haiku 3モデルのコストを計算する' do
        cost = described_class.calculate_cost(haiku_model, 1000, 500)
        expect(cost).to eq(0.000875)
      end
    end

    it '不明なモデルに対して0を返す' do
      cost = described_class.calculate_cost('unknown-model', 1000, 500)
      expect(cost).to eq(0)
    end

    it 'トークン数0の場合0を返す' do
      cost = described_class.calculate_cost('us.anthropic.claude-sonnet-4-5-20250929-v1:0', 0, 0)
      expect(cost).to eq(0)
    end
  end

  describe '.display_name' do
    context 'Claude 4.5モデル' do
      it 'Sonnet 4.5の表示名を返す' do
        expect(described_class.display_name('us.anthropic.claude-sonnet-4-5-20250929-v1:0')).to eq('Claude Sonnet 4.5')
      end

      it 'Haiku 4.5の表示名を返す' do
        expect(described_class.display_name('us.anthropic.claude-haiku-4-5-20251001-v1:0')).to eq('Claude Haiku 4.5')
      end
    end

    context 'Claude 3.5/3モデル（後方互換性）' do
      it 'Sonnet 3.5の表示名を返す' do
        expect(described_class.display_name('anthropic.claude-3-5-sonnet-20241022-v2:0')).to eq('Claude 3.5 Sonnet')
        expect(described_class.display_name('us.anthropic.claude-3-5-sonnet-20241022-v2:0')).to eq('Claude 3.5 Sonnet')
      end

      it 'Haiku 3の表示名を返す' do
        expect(described_class.display_name('anthropic.claude-3-haiku-20240307-v1:0')).to eq('Claude 3 Haiku')
        expect(described_class.display_name('us.anthropic.claude-3-haiku-20240307-v1:0')).to eq('Claude 3 Haiku')
      end
    end

    it '不明なモデルはそのまま返す' do
      expect(described_class.display_name('unknown-model')).to eq('unknown-model')
    end
  end

  describe '.available?' do
    context 'Claude 4.5モデル' do
      it 'Sonnet 4.5に対してtrueを返す' do
        expect(described_class.available?('us.anthropic.claude-sonnet-4-5-20250929-v1:0')).to be true
      end

      it 'Haiku 4.5に対してtrueを返す' do
        expect(described_class.available?('us.anthropic.claude-haiku-4-5-20251001-v1:0')).to be true
      end
    end

    context 'Claude 3.5/3モデル（後方互換性）' do
      it 'Sonnet 3.5に対してtrueを返す' do
        expect(described_class.available?('us.anthropic.claude-3-5-sonnet-20241022-v2:0')).to be true
        expect(described_class.available?('anthropic.claude-3-5-sonnet-20241022-v2:0')).to be true
      end

      it 'Haiku 3に対してtrueを返す' do
        expect(described_class.available?('us.anthropic.claude-3-haiku-20240307-v1:0')).to be true
        expect(described_class.available?('anthropic.claude-3-haiku-20240307-v1:0')).to be true
      end
    end

    it '不明なモデルに対してfalseを返す' do
      expect(described_class.available?('unknown-model')).to be false
    end
  end
end
