require "rails_helper"

RSpec.describe Ai::StructureSuggester do
  let(:admin_user) { create(:admin_user) }
  let(:suggester) { described_class.new(admin_user: admin_user) }

  describe "#suggest" do
    context "markdown形式" do
      it "Markdownの構成案を返す" do
        mock_bedrock_client(response_content: "## はじめに\n<!-- 導入 -->")

        result = suggester.suggest(topic: "Railsテスト", format: "markdown")

        expect(result[:success]).to be true
        expect(result[:data][:structure]).to include("## はじめに")
      end
    end

    context "json形式" do
      it "JSONの構成案をパースして返す" do
        mock_bedrock_client(response_content: mock_structure_response)

        result = suggester.suggest(topic: "Railsテスト", format: "json")

        expect(result[:success]).to be true
        expect(result[:data][:structure]).to be_a(Hash)
        expect(result[:data][:structure][:sections]).to be_an(Array)
      end

      it "サブセクションを含む構造をパースできる" do
        response = {
          title_suggestions: [ "案1" ],
          sections: [
            {
              heading: "親セクション",
              level: 2,
              description: "説明",
              recommended_words: 300,
              subsections: [
                { heading: "子セクション", level: 3, description: "詳細", recommended_words: 150 }
              ]
            }
          ],
          total_recommended_words: 1000,
          related_topics: [],
          keywords: []
        }.to_json
        mock_bedrock_client(response_content: response)

        result = suggester.suggest(topic: "RSpec", format: "json")

        section = result[:data][:structure][:sections].first
        expect(section[:subsections].first[:heading]).to eq("子セクション")
      end
    end

    context "共通" do
      it "AiGenerationレコードを作成してcompletedにする" do
        mock_bedrock_client(response_content: mock_structure_response)

        suggester.suggest(topic: "構成", format: "json")

        generation = AiGeneration.last
        expect(generation.status).to eq("completed")
        expect(generation.generation_type).to eq("structure")
      end
    end

    context "異常系" do
      it "トピックが空の場合はエラーを返す" do
        result = suggester.suggest(topic: "", format: "markdown")

        expect(result[:success]).to be false
        expect(result[:error]).to include("トピックを入力してください")
      end

      it "無効な詳細レベルの場合はエラーを返す" do
        result = suggester.suggest(topic: "構成", detail_level: "invalid", format: "markdown")

        expect(result[:success]).to be false
        expect(result[:error]).to include("無効な詳細レベル")
      end

      it "無効な出力形式の場合はエラーを返す" do
        result = suggester.suggest(topic: "構成", format: "xml")

        expect(result[:success]).to be false
        expect(result[:error]).to include("無効な出力形式")
      end

      it "APIエラー時はfailedになる" do
        mock_bedrock_error(message: "Service Error")

        result = suggester.suggest(topic: "構成", format: "markdown")

        expect(result[:success]).to be false
        expect(AiGeneration.last.status).to eq("failed")
      end
    end
  end

  describe "#build_json_prompt" do
    it "トピックと詳細度を含む" do
      prompt = suggester.send(:build_json_prompt, "Topic", "basic")

      expect(prompt).to include("Topic")
      expect(prompt).to include("basic")
    end
  end

  describe "#build_markdown_prompt" do
    it "詳細度に応じたセクション数の目安を含む" do
      prompt = suggester.send(:build_markdown_prompt, "Topic", "comprehensive")

      expect(prompt).to include("8〜10セクション")
    end
  end
end
