require 'rails_helper'

RSpec.describe Ai::SummaryGenerator do
  let(:article) { create(:article, content: 'テスト記事の本文内容です。これは長い記事です。') }
  let(:admin_user) { create(:admin_user) }
  let(:generator) { described_class.new(article: article, admin_user: admin_user) }

  describe '#generate' do
    context '正常系' do
      before do
        mock_bedrock_client(response_content: mock_summary_response)
      end

      it '要約を生成して成功結果を返す' do
        result = generator.generate

        expect(result[:success]).to be true
        expect(result[:data][:summaries]).to be_an(Array)
        expect(result[:data][:summaries].length).to eq(3)
      end

      it 'AiGenerationレコードを作成する' do
        expect { generator.generate }.to change(AiGeneration, :count).by(1)
      end

      it 'AiGenerationレコードをcompletedで更新する' do
        generator.generate
        generation = AiGeneration.last
        expect(generation.status).to eq('completed')
        expect(generation.generation_type).to eq('summary')
      end

      it 'generation_idを返す' do
        result = generator.generate
        expect(result[:data][:generation_id]).to be_present
      end

      it '短い長さを指定できる' do
        result = generator.generate(length: 'short')
        expect(result[:success]).to be true
      end

      it '長い長さを指定できる' do
        result = generator.generate(length: 'long')
        expect(result[:success]).to be true
      end

      it '生成数を指定できる' do
        mock_bedrock_client(response_content: mock_summary_response(count: 5))
        result = generator.generate(count: 5)
        expect(result[:success]).to be true
      end
    end

    context '異常系' do
      it 'articleがない場合、エラー結果を返す' do
        generator = described_class.new(article: nil)
        result = generator.generate

        expect(result[:success]).to be false
        expect(result[:error]).to include('Article is required')
      end

      it '記事内容が空の場合、エラー結果を返す' do
        article.update_column(:content, '')
        result = generator.generate

        expect(result[:success]).to be false
        expect(result[:error]).to include('content is required')
      end

      it '無効な長さの場合、エラー結果を返す' do
        result = generator.generate(length: 'invalid')

        expect(result[:success]).to be false
        expect(result[:error]).to include('Invalid length')
      end

      it 'APIエラーの場合、エラー結果を返しAiGenerationをfailedにする' do
        mock_bedrock_error(message: 'API Error')

        result = generator.generate

        expect(result[:success]).to be false
        expect(result[:error]).to include('API Error')

        generation = AiGeneration.last
        expect(generation.status).to eq('failed')
      end
    end
  end
end
