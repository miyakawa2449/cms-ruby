require "rails_helper"

RSpec.describe Ai::SlugGenerator do
  let(:admin_user) { create(:admin_user) }
  let(:article) { create(:article, title: "テスト記事", content: "本文", admin_user: admin_user) }
  let(:generator) { described_class.new(article: article, admin_user: admin_user) }

  describe "#generate" do
    context "正常系" do
      before do
        mock_bedrock_client(response_content: mock_slug_response)
      end

      it "スラッグ候補を返す" do
        result = generator.generate

        expect(result[:success]).to be true
        expect(result[:data][:slugs]).to be_an(Array)
        expect(result[:data][:slugs].first[:slug]).to eq("test-article-slug")
      end

      it "seo_scoreが高い順に並ぶ" do
        result = generator.generate

        scores = result[:data][:slugs].map { |slug| slug[:seo_score] }
        expect(scores).to eq(scores.sort.reverse)
      end

      it "AiGenerationレコードを作成してcompletedにする" do
        generator.generate

        generation = AiGeneration.last
        expect(generation.status).to eq("completed")
        expect(generation.generation_type).to eq("slug")
      end

      it "既存スラッグがある場合はavailableがfalseになる" do
        create(:article, slug: "test-article-slug", status: "published", published_at: Time.current)

        result = generator.generate

        unavailable = result[:data][:slugs].find { |slug| slug[:slug] == "test-article-slug" }
        expect(unavailable[:available]).to be false
      end

      it "指定したタイトルで生成できる" do
        result = generator.generate(title: "カスタムタイトル")

        expect(result[:success]).to be true
        expect(result[:data][:slugs]).to be_present
      end

      it "不正なJSONレスポンスでも空配列を返す" do
        mock_bedrock_client(response_content: "not-json")

        result = generator.generate

        expect(result[:success]).to be true
        expect(result[:data][:slugs]).to eq([])
      end
    end

    context "異常系" do
      it "タイトルが空の場合はエラーを返す" do
        result = generator.generate(title: "")

        expect(result[:success]).to be false
        expect(result[:error]).to include("Title is required")
      end

      it "記事がなくてもタイトル指定があれば生成できる" do
        mock_bedrock_client(response_content: mock_slug_response)
        generator = described_class.new(article: nil, admin_user: admin_user)

        result = generator.generate(title: "単独タイトル")

        expect(result[:success]).to be true
        expect(AiGeneration.last.article).to be_nil
      end

      it "APIエラー時はfailedになる" do
        mock_bedrock_error(message: "Service Error")

        result = generator.generate

        expect(result[:success]).to be false
        expect(AiGeneration.last.status).to eq("failed")
      end
    end
  end

  describe "#build_prompt" do
    it "タイトルと件数を含む" do
      prompt = generator.send(:build_prompt, "タイトル", 5)

      expect(prompt).to include("タイトル: タイトル")
      expect(prompt).to include("5つ")
    end
  end

  describe "#normalize_slug" do
    it "スラッグを正規化する" do
      normalized = generator.send(:normalize_slug, "Test Slug!!")

      expect(normalized).to eq("test-slug")
    end
  end
end
