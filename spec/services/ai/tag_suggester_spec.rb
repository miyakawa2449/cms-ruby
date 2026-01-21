require 'rails_helper'

RSpec.describe Ai::TagSuggester do
  let(:article) { create(:article, content: 'Rubyプログラミングの基礎を学ぶ記事です。') }
  let(:admin_user) { create(:admin_user) }
  let(:suggester) { described_class.new(article: article, admin_user: admin_user) }

  before do
    create(:tag, name: 'Ruby', slug: 'ruby')
    create(:tag, name: 'Rails', slug: 'rails')
    create(:tag, name: 'Programming', slug: 'programming')
  end

  describe '#suggest' do
    context '正常系' do
      before do
        mock_bedrock_client(response_content: mock_tag_response)
      end

      it 'タグを提案して成功結果を返す' do
        result = suggester.suggest

        expect(result[:success]).to be true
        expect(result[:data][:suggested_tags]).to be_an(Array)
      end

      it 'AiGenerationレコードを作成する' do
        expect { suggester.suggest }.to change(AiGeneration, :count).by(1)
      end

      it 'AiGenerationレコードをcompletedで更新する' do
        suggester.suggest
        generation = AiGeneration.last
        expect(generation.status).to eq('completed')
        expect(generation.generation_type).to eq('tags')
      end

      it '既存タグにはtag_idが付与される' do
        result = suggester.suggest
        ruby_tag = result[:data][:suggested_tags].find { |t| t[:name] == 'Ruby' }
        expect(ruby_tag[:existing]).to be true
        expect(ruby_tag[:tag_id]).to be_present
      end

      it '新規タグにはtag_idがnilになる' do
        result = suggester.suggest
        new_tag = result[:data][:suggested_tags].find { |t| t[:name] == '新規タグ' }
        expect(new_tag[:existing]).to be false
        expect(new_tag[:tag_id]).to be_nil
      end

      it 'max_tagsを指定できる' do
        result = suggester.suggest(max_tags: 10)
        expect(result[:success]).to be true
      end

      it 'include_existingをfalseにすると既存タグを参照しない' do
        mock_bedrock_client(response_content: mock_tag_response(tags: [ { name: 'Ruby', confidence: 0.9 } ]))

        result = suggester.suggest(include_existing: false)

        expect(result[:success]).to be true
        expect(result[:data][:suggested_tags].first[:existing]).to be false
        expect(result[:data][:suggested_tags].first[:tag_id]).to be_nil
      end

      it '不正なJSONレスポンスでも空配列を返す' do
        mock_bedrock_client(response_content: "not-json")

        result = suggester.suggest

        expect(result[:success]).to be true
        expect(result[:data][:suggested_tags]).to eq([])
      end
    end

    context '異常系' do
      it 'articleがない場合、エラー結果を返す' do
        suggester = described_class.new(article: nil)
        result = suggester.suggest

        expect(result[:success]).to be false
        expect(result[:error]).to include('Article is required')
      end

      it 'APIエラーの場合、エラー結果を返す' do
        mock_bedrock_error(message: 'API Error')

        result = suggester.suggest

        expect(result[:success]).to be false
        expect(AiGeneration.last.status).to eq('failed')
      end
    end
  end
end
