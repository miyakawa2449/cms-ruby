# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ai::TitleSuggester, type: :service do
  let(:admin_user) { create(:admin_user) }
  let(:article) do
    create(:article,
           title: "既存のタイトル",
           content: "これはテスト記事の本文です。" * 50)
  end
  let(:suggester) { described_class.new(article: article, admin_user: admin_user) }

  describe '#suggest' do
    context 'when article has content' do
      it 'returns success with descriptive and engaging titles' do
        # Mock Bedrock API response
        allow(suggester).to receive(:call_bedrock_api).and_return(
          {
            "descriptive_titles" => [
              { "title" => "わかりやすいタイトル1", "reason" => "内容を正確に表現" },
              { "title" => "わかりやすいタイトル2", "reason" => "検索に最適化" }
            ],
            "engaging_titles" => [
              { "title" => "クリックしたくなるタイトル1", "reason" => "好奇心を刺激" },
              { "title" => "クリックしたくなるタイトル2", "reason" => "感情に訴える" }
            ]
          }.to_json
        )

        result = suggester.suggest(count: 2)

        expect(result[:success]).to be true
        expect(result[:data][:descriptive_titles]).to be_an(Array)
        expect(result[:data][:engaging_titles]).to be_an(Array)
        expect(result[:data][:descriptive_titles].size).to eq(2)
        expect(result[:data][:engaging_titles].size).to eq(2)
        expect(result[:data][:current_title]).to eq("既存のタイトル")
      end
    end

    context 'when article has no content' do
      let(:article) { create(:article, content: nil) }

      it 'raises an error' do
        expect { suggester.suggest }.to raise_error(ArgumentError, "記事の本文が必要です")
      end
    end

    context 'when article is nil' do
      let(:article) { nil }

      it 'raises an error' do
        expect { suggester.suggest }.to raise_error(ArgumentError, "記事が必要です")
      end
    end
  end
end
