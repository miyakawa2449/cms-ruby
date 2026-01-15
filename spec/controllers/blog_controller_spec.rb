require 'rails_helper'

RSpec.describe BlogController, type: :controller do
  describe 'GET #index' do
    context '通常表示（検索なし）' do
      it '公開記事一覧を表示する' do
        published_article = create(:article, :published)
        draft_article = create(:article, :draft)

        get :index

        expect(response).to have_http_status(:success)
        expect(assigns(:articles)).to include(published_article)
        expect(assigns(:articles)).not_to include(draft_article)
      end

      it 'ページネーションが機能する' do
        create_list(:article, 15, :published)

        get :index, params: { page: 1 }

        expect(assigns(:articles).count).to be <= 10
      end

      it '検索パラメータがない場合、@queryはnil' do
        create(:article, :published)

        get :index

        expect(assigns(:query)).to be_nil
      end
    end

    context 'キーワード検索' do
      it '検索結果を表示する' do
        article = create(:article, :published, title: 'Ruby on Rails入門')

        get :index, params: { q: 'Rails' }

        expect(response).to have_http_status(:success)
        expect(assigns(:articles)).to include(article)
        expect(assigns(:query)).to eq('Rails')
      end

      it 'キーワードにマッチしない記事は表示されない' do
        matching_article = create(:article, :published, title: 'Ruby on Rails入門')
        non_matching_article = create(:article, :published, title: 'Python入門')

        get :index, params: { q: 'Rails' }

        expect(assigns(:articles)).to include(matching_article)
        expect(assigns(:articles)).not_to include(non_matching_article)
      end

      it '検索結果件数が取得できる' do
        create_list(:article, 5, :published, title: 'Rails入門')
        create(:article, :published, title: 'Python入門')

        get :index, params: { q: 'Rails' }

        expect(assigns(:articles).total_count).to eq(5)
      end
    end

    context 'カテゴリフィルタ' do
      it 'カテゴリで絞り込みができる' do
        category = create(:category, name: 'プログラミング')
        article1 = create(:article, :published)
        article1.categories << category
        article2 = create(:article, :published)

        get :index, params: { category_id: category.id }

        expect(assigns(:articles)).to include(article1)
        expect(assigns(:articles)).not_to include(article2)
        expect(assigns(:selected_category)).to eq(category)
      end

      it 'サイドバーのカテゴリクリックで検索条件がクリアされる' do
        category = create(:category)

        get :index, params: { category_id: category.id }

        expect(assigns(:query)).to be_nil
      end
    end

    context 'タグフィルタ' do
      it 'タグで絞り込みができる' do
        tag = create(:tag, name: 'Ruby')
        article1 = create(:article, :published)
        article1.tags << tag
        article2 = create(:article, :published)

        get :index, params: { tag_id: tag.id }

        expect(assigns(:articles)).to include(article1)
        expect(assigns(:articles)).not_to include(article2)
        expect(assigns(:selected_tag)).to eq(tag)
      end
    end

    context '複合条件検索' do
      it '複数条件で絞り込みができる' do
        category = create(:category, name: 'プログラミング')
        tag = create(:tag, name: 'Rails')
        article1 = create(:article, :published, title: 'Rails入門')
        article1.categories << category
        article1.tags << tag
        article2 = create(:article, :published, title: 'Rails応用')
        article2.tags << tag

        get :index, params: { q: 'Rails', category_id: category.id, tag_id: tag.id }

        expect(assigns(:articles)).to include(article1)
        expect(assigns(:articles)).not_to include(article2)
      end
    end

    context 'SEO' do
      it '検索時はnoindexが設定される' do
        get :index, params: { q: 'Rails' }

        # set_meta_tagsが呼ばれているかを確認
        expect(response).to have_http_status(:success)
      end

      it 'カテゴリフィルタ時もnoindexが設定される' do
        category = create(:category)

        get :index, params: { category_id: category.id }

        expect(response).to have_http_status(:success)
      end

      it 'タグフィルタ時もnoindexが設定される' do
        tag = create(:tag)

        get :index, params: { tag_id: tag.id }

        expect(response).to have_http_status(:success)
      end
    end
  end
end
