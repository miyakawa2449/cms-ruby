# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::AiController, type: :request do
  let(:admin_user) { create(:admin_user) }
  let(:article) { create(:article, :published, content: "テスト記事の本文です。" * 50) }

  before do
    sign_in admin_user, scope: :admin_user
  end

  describe 'POST /admin/articles/:article_id/ai/suggest_title' do
    let(:mock_result) do
      {
        success: true,
        data: {
          descriptive_titles: [
            { title: "わかりやすいタイトル1", reason: "内容を正確に表現" },
            { title: "わかりやすいタイトル2", reason: "検索に最適化" }
          ],
          engaging_titles: [
            { title: "クリックしたくなるタイトル1", reason: "好奇心を刺激" },
            { title: "クリックしたくなるタイトル2", reason: "感情に訴える" }
          ],
          current_title: article.title
        }
      }
    end

    before do
      allow_any_instance_of(Ai::TitleSuggester).to receive(:suggest).and_return(mock_result)
    end

    it 'returns title suggestions' do
      post admin_article_ai_suggest_title_path(article_id: article.id),
           params: { count: 2 },
           headers: { "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" }

      puts "status=#{response.status}"
      puts "body=#{response.body}"
      puts "content_type=#{response.headers['Content-Type']}"
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
      expect(json['data']['descriptive_titles']).to be_an(Array)
      expect(json['data']['engaging_titles']).to be_an(Array)
    end

    context 'when count parameter is provided' do
      it 'passes count to suggester' do
        expect_any_instance_of(Ai::TitleSuggester).to receive(:suggest).with(count: 5)

        post admin_article_ai_suggest_title_path(article_id: article.id),
             params: { count: 5 }
      end
    end
  end
end
