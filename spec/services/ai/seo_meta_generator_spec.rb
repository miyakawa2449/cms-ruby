require "rails_helper"

RSpec.describe Ai::SeoMetaGenerator do
  let(:admin_user) { create(:admin_user) }
  let(:article) { create(:article, title: "SEOタイトル", content: "本文" * 200, admin_user: admin_user) }
  let(:generator) { described_class.new(article: article, admin_user: admin_user) }

  describe "#generate" do
    context "正常系" do
      before do
        mock_bedrock_client(response_content: mock_seo_meta_response)
      end

      it "SEOメタデータを返す" do
        result = generator.generate

        expect(result[:success]).to be true
        expect(result[:data]).to include("meta_description", "meta_keywords", "og_title", "og_description")
      end

      it "指定フィールドのみ生成できる" do
        result = generator.generate(fields: %w[meta_description og_title])

        expect(result[:success]).to be true
        expect(result[:data].keys).to include("meta_description", "og_title")
      end

      it "AiGenerationレコードを作成してcompletedにする" do
        expect { generator.generate }.to change(AiGeneration, :count).by(1)

        generation = AiGeneration.last
        expect(generation.status).to eq("completed")
        expect(generation.generation_type).to eq("seo_meta")
      end

      it "meta_descriptionは160文字に切り詰められる" do
        long_description = "a" * 200
        mock_bedrock_client(response_content: { meta_description: long_description }.to_json)

        result = generator.generate(fields: [ "meta_description" ])

        expect(result[:data]["meta_description"].length).to eq(160)
      end

      it "og_titleは60文字に切り詰められる" do
        long_title = "b" * 100
        mock_bedrock_client(response_content: { og_title: long_title }.to_json)

        result = generator.generate(fields: [ "og_title" ])

        expect(result[:data]["og_title"].length).to eq(60)
      end

      it "og_descriptionは200文字に切り詰められる" do
        long_description = "c" * 250
        mock_bedrock_client(response_content: { og_description: long_description }.to_json)

        result = generator.generate(fields: [ "og_description" ])

        expect(result[:data]["og_description"].length).to eq(200)
      end
    end

    context "異常系" do
      it "不正なフィールド指定でエラーを返す" do
        result = generator.generate(fields: [ "invalid_field" ])

        expect(result[:success]).to be false
        expect(result[:error]).to include("Invalid fields")
      end

      it "記事がない場合はエラーを返す" do
        generator = described_class.new(article: nil, admin_user: admin_user)

        result = generator.generate

        expect(result[:success]).to be false
        expect(result[:error]).to include("Article is required")
      end

      it "本文が空の場合はエラーを返す" do
        article.update_column(:content, "")

        result = generator.generate

        expect(result[:success]).to be false
        expect(result[:error]).to include("Article content is required")
      end

      it "APIエラー時はfailedになる" do
        mock_bedrock_error(message: "Service Error")

        result = generator.generate

        expect(result[:success]).to be false
        expect(AiGeneration.last.status).to eq("failed")
      end
    end
  end
end
