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
        mock_bedrock_client(
          response_content: {
            descriptive_titles: [
              { title: "わかりやすいタイトル1", reason: "内容を正確に表現" },
              { title: "わかりやすいタイトル2", reason: "検索に最適化" }
            ],
            engaging_titles: [
              { title: "クリックしたくなるタイトル1", reason: "好奇心を刺激" },
              { title: "クリックしたくなるタイトル2", reason: "感情に訴える" }
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

      it 'creates an AiGeneration record' do
        mock_bedrock_client(response_content: { descriptive_titles: [], engaging_titles: [] }.to_json)

        expect { suggester.suggest }.to change(AiGeneration, :count).by(1)
      end

      it 'marks the generation as completed' do
        mock_bedrock_client(response_content: { descriptive_titles: [], engaging_titles: [] }.to_json)

        suggester.suggest

        generation = AiGeneration.last
        expect(generation.status).to eq("completed")
        expect(generation.generation_type).to eq("title")
      end

      it 'includes the count in the prompt' do
        prompt = suggester.send(:build_prompt, 5)

        expect(prompt).to include("5")
        expect(prompt).to include("わかりやすいタイトル")
      end

      it 'includes the current title in the prompt' do
        prompt = suggester.send(:build_prompt, 3)

        expect(prompt).to include("既存のタイトル")
      end

      it 'handles invalid JSON responses by returning empty arrays' do
        mock_bedrock_client(response_content: "not-json")

        result = suggester.suggest

        expect(result[:success]).to be true
        expect(result[:data][:descriptive_titles]).to eq([])
        expect(result[:data][:engaging_titles]).to eq([])
      end

      it 'includes generation metadata in the response' do
        mock_bedrock_client(response_content: { descriptive_titles: [], engaging_titles: [] }.to_json)

        result = suggester.suggest

        expect(result[:data][:generation_id]).to be_present
        expect(result[:data][:tokens_used]).to be_present
        expect(result[:data][:cost]).to be_present
      end
    end

    context 'when article has no content' do
      let(:article) { build(:article, content: nil) }

      it 'returns an error result' do
        result = suggester.suggest

        expect(result[:success]).to be false
        expect(result[:error]).to include("記事の本文が必要です")
      end
    end

    context 'when article is nil' do
      let(:article) { nil }

      it 'returns an error result' do
        result = suggester.suggest

        expect(result[:success]).to be false
        expect(result[:error]).to include("記事が必要です")
      end
    end

    context 'when API raises an error' do
      it 'returns an error result and marks generation as failed' do
        mock_bedrock_error(message: "Service Error")

        result = suggester.suggest

        expect(result[:success]).to be false
        expect(result[:error]).to include("Bedrock API error")
        expect(AiGeneration.last.status).to eq("failed")
      end
    end
  end
end
