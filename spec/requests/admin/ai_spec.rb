require 'rails_helper'

RSpec.describe "Admin::Ai", type: :request do
  let(:admin_user) { create(:admin_user) }
  let(:article) { create(:article, admin_user: admin_user) }

  before do
    sign_in admin_user, scope: :admin_user
  end

  describe "POST /admin/articles/:article_id/ai/generate_summary" do
    context "正常系" do
      before do
        mock_bedrock_client(response_content: mock_summary_response)
      end

      it "要約を生成して返す" do
        post admin_article_ai_generate_summary_path(article_id: article.id)

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['data']['summaries']).to be_an(Array)
      end

      it "length パラメータを受け付ける" do
        post admin_article_ai_generate_summary_path(article_id: article.id),
             params: { length: 'short', count: 2 }

        expect(response).to have_http_status(:success)
      end

      it "AiGeneration レコードを作成する" do
        expect {
          post admin_article_ai_generate_summary_path(article_id: article.id)
        }.to change(AiGeneration, :count).by(1)
      end
    end

    context "異常系" do
      it "存在しない記事IDでは404を返す" do
        post admin_article_ai_generate_summary_path(article_id: 99999)

        expect(response).to have_http_status(:not_found)
      end

      it "AI機能が利用不可の場合503を返す" do
        allow_any_instance_of(Admin::AiController).to receive(:ai_service_available?).and_return(false)

        post admin_article_ai_generate_summary_path(article_id: article.id)

        expect(response).to have_http_status(:service_unavailable)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['error']).to include('AI機能は現在利用できません')
      end

      it "APIエラー時はエラーレスポンスを返す" do
        mock_bedrock_error

        post admin_article_ai_generate_summary_path(article_id: article.id)

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
      end
    end
  end

  describe "POST /admin/articles/:article_id/ai/suggest_tags" do
    context "正常系" do
      before do
        mock_bedrock_client(response_content: mock_tag_response)
      end

      it "タグ提案を返す" do
        post admin_article_ai_suggest_tags_path(article_id: article.id)

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['data']).to have_key('suggested_tags')
      end

      it "max_tags パラメータを受け付ける" do
        post admin_article_ai_suggest_tags_path(article_id: article.id),
             params: { max_tags: 5 }

        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "POST /admin/articles/:article_id/ai/generate_slug" do
    context "正常系" do
      before do
        mock_bedrock_client(response_content: mock_slug_response)
      end

      it "スラッグ候補を返す" do
        post admin_article_ai_generate_slug_path(article_id: article.id)

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['data']['slugs']).to be_an(Array)
      end

      it "タイトルパラメータを受け付ける" do
        post admin_article_ai_generate_slug_path(article_id: article.id),
             params: { title: 'カスタムタイトル', count: 5 }

        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "POST /admin/articles/:article_id/ai/generate_seo_meta" do
    context "正常系" do
      before do
        mock_bedrock_client(response_content: mock_seo_meta_response)
      end

      it "SEOメタデータを返す" do
        post admin_article_ai_generate_seo_meta_path(article_id: article.id)

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['data']).to have_key('meta_description')
      end

      it "フィールド指定を受け付ける" do
        post admin_article_ai_generate_seo_meta_path(article_id: article.id),
             params: { fields: [ 'meta_description', 'og_title' ] }

        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "POST /admin/ai/suggest_structure" do
    context "正常系" do
      before do
        mock_bedrock_client(response_content: mock_structure_response)
      end

      it "記事構成案を返す" do
        post admin_ai_suggest_structure_path, params: { topic: 'Railsのテスト' }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['data']['structure']).to have_key('sections')
      end

      it "detail_level パラメータを受け付ける" do
        post admin_ai_suggest_structure_path,
             params: { topic: 'Ruby入門', detail_level: 'comprehensive' }

        expect(response).to have_http_status(:success)
      end
    end

    context "異常系" do
      it "トピックが空の場合エラーを返す" do
        post admin_ai_suggest_structure_path, params: { topic: '' }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
      end
    end
  end

  describe "GET /admin/ai/usage_stats" do
    before do
      # Create some AI generation records for stats
      create(:ai_generation, :completed, admin_user: admin_user, article: article)
      create(:ai_generation, :completed, admin_user: admin_user, article: article)
    end

    context "正常系" do
      it "使用統計を返す" do
        get admin_ai_usage_stats_path

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['data']).to be_present
      end

      it "期間パラメータを受け付ける" do
        get admin_ai_usage_stats_path, params: { period: 'today' }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
      end

      it "週間統計を取得できる" do
        get admin_ai_usage_stats_path, params: { period: 'week' }

        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "認証" do
    context "未認証ユーザー" do
      before do
        sign_out :admin_user
      end

      it "未認証ユーザーはリダイレクトされる" do
        post admin_article_ai_generate_summary_path(article_id: article.id)

        expect(response).to redirect_to(new_admin_user_session_path)
      end

      it "未認証ユーザーは使用統計にアクセスできない" do
        get admin_ai_usage_stats_path

        expect(response).to redirect_to(new_admin_user_session_path)
      end
    end
  end

  describe "スラッグによる記事検索" do
    let(:article_with_slug) { create(:article, slug: 'my-test-article', admin_user: admin_user) }

    before do
      mock_bedrock_client(response_content: mock_summary_response)
    end

    it "スラッグで記事を検索できる" do
      post admin_article_ai_generate_summary_path(article_id: article_with_slug.slug)

      expect(response).to have_http_status(:success)
    end
  end
end
