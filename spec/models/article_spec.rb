require 'rails_helper'

RSpec.describe Article, type: :model do
  describe '.search' do
    context '正常系' do
      it 'キーワードがタイトルに含まれる記事を返す' do
        article = create(:article, title: 'Ruby on Rails入門')
        other = create(:article, title: 'Python入門')

        result = Article.search('Rails')

        expect(result).to include(article)
        expect(result).not_to include(other)
      end

      it 'キーワードが本文に含まれる記事を返す' do
        article = create(:article, title: 'Web開発', content: 'Railsは強力なフレームワークです')
        other = create(:article, title: 'Web開発', content: 'Djangoは強力なフレームワークです')

        result = Article.search('Rails')

        expect(result).to include(article)
        expect(result).not_to include(other)
      end

      it 'キーワードが抜粋に含まれる記事を返す' do
        article = create(:article, excerpt: 'Railsの基礎を学ぶ')
        other = create(:article, excerpt: 'Pythonの基礎を学ぶ')

        result = Article.search('Rails')

        expect(result).to include(article)
        expect(result).not_to include(other)
      end

      it '複数の記事がマッチする場合、すべて返す' do
        article1 = create(:article, title: 'Rails入門')
        article2 = create(:article, title: 'Rails応用')
        other = create(:article, title: 'Python入門')

        result = Article.search('Rails')

        expect(result).to include(article1, article2)
        expect(result).not_to include(other)
      end

      it '大文字小文字を区別せずに検索できる' do
        article = create(:article, title: 'Ruby on Rails入門')

        result1 = Article.search('rails')
        result2 = Article.search('RAILS')
        result3 = Article.search('Rails')

        expect(result1).to include(article)
        expect(result2).to include(article)
        expect(result3).to include(article)
      end
    end

    context '異常系' do
      it 'キーワードが空文字の場合、全件を返す' do
        create_list(:article, 3)

        result = Article.search('')

        expect(result.count).to eq(3)
      end

      it 'キーワードがnilの場合、全件を返す' do
        create_list(:article, 3)

        result = Article.search(nil)

        expect(result.count).to eq(3)
      end

      it 'マッチする記事がない場合、空のリレーションを返す' do
        create(:article, title: 'Ruby入門')

        result = Article.search('存在しないキーワード')

        expect(result).to be_empty
      end
    end

    context 'エッジケース' do
      it 'SQLワイルドカード（%）を含むキーワードで検索できる' do
        article = create(:article, title: '100%達成')
        other = create(:article, title: '100点達成')

        result = Article.search('100%')

        expect(result).to include(article)
        expect(result).not_to include(other)
      end

      it 'SQLワイルドカード（_）を含むキーワードで検索できる' do
        article = create(:article, title: 'test_data')
        other = create(:article, title: 'testXdata')

        result = Article.search('test_')

        expect(result).to include(article)
        expect(result).not_to include(other)
      end

      it 'バックスラッシュ（\）を含むキーワードで検索できる' do
        article = create(:article, title: 'C:\\Program Files')
        other = create(:article, title: 'C:/Program Files')

        result = Article.search('C:\\')

        expect(result).to include(article)
        expect(result).not_to include(other)
      end

      it '前後の空白を無視して検索できる' do
        article = create(:article, title: 'Ruby on Rails')

        result = Article.search('  Rails  ')

        expect(result).to include(article)
      end
    end
  end

  describe '.by_category' do
    let(:category1) { create(:category, name: 'プログラミング') }
    let(:category2) { create(:category, name: 'インフラ') }

    context '正常系' do
      it '指定したカテゴリの記事を返す' do
        article1 = create(:article)
        article1.categories << category1
        article2 = create(:article)
        article2.categories << category2

        result = Article.by_category(category1.id)

        expect(result).to include(article1)
        expect(result).not_to include(article2)
      end

      it 'カテゴリに属する記事が複数ある場合、すべて返す' do
        article1 = create(:article)
        article1.categories << category1
        article2 = create(:article)
        article2.categories << category1

        result = Article.by_category(category1.id)

        expect(result).to include(article1, article2)
      end
    end

    context '異常系' do
      it 'カテゴリIDがnilの場合、全件を返す' do
        create_list(:article, 3)

        result = Article.by_category(nil)

        expect(result.count).to eq(3)
      end

      it 'カテゴリIDが空文字の場合、全件を返す' do
        create_list(:article, 3)

        result = Article.by_category('')

        expect(result.count).to eq(3)
      end

      it '存在しないカテゴリIDの場合、空のリレーションを返す' do
        article = create(:article)
        article.categories << category1

        result = Article.by_category(99999)

        expect(result).to be_empty
      end
    end
  end

  describe '.by_tag' do
    let(:tag1) { create(:tag, name: 'Ruby') }
    let(:tag2) { create(:tag, name: 'Rails') }

    context '正常系' do
      it '指定したタグの記事を返す' do
        article1 = create(:article)
        article1.tags << tag1
        article2 = create(:article)
        article2.tags << tag2

        result = Article.by_tag(tag1.id)

        expect(result).to include(article1)
        expect(result).not_to include(article2)
      end

      it 'タグに属する記事が複数ある場合、すべて返す' do
        article1 = create(:article)
        article1.tags << tag1
        article2 = create(:article)
        article2.tags << tag1

        result = Article.by_tag(tag1.id)

        expect(result).to include(article1, article2)
      end
    end

    context '異常系' do
      it 'タグIDがnilの場合、全件を返す' do
        create_list(:article, 3)

        result = Article.by_tag(nil)

        expect(result.count).to eq(3)
      end

      it 'タグIDが空文字の場合、全件を返す' do
        create_list(:article, 3)

        result = Article.by_tag('')

        expect(result.count).to eq(Article.count)
      end

      it '存在しないタグIDの場合、空のリレーションを返す' do
        article = create(:article)
        article.tags << tag1

        result = Article.by_tag(99999)

        expect(result).to be_empty
      end
    end
  end

  describe '.by_tags' do
    let(:tag1) { create(:tag, name: 'Ruby') }
    let(:tag2) { create(:tag, name: 'Rails') }
    let(:tag3) { create(:tag, name: 'Python') }

    context '正常系' do
      it '指定したタグの記事を返す' do
        article1 = create(:article)
        article1.tags << tag1
        article2 = create(:article)
        article2.tags << tag3

        result = Article.by_tags([ tag1.id ])

        expect(result).to include(article1)
        expect(result).not_to include(article2)
      end

      it '複数のタグIDを指定した場合、いずれかのタグを持つ記事を返す' do
        article1 = create(:article)
        article1.tags << tag1
        article2 = create(:article)
        article2.tags << tag2
        article3 = create(:article)
        article3.tags << tag3

        result = Article.by_tags([ tag1.id, tag2.id ])

        expect(result).to include(article1, article2)
        expect(result).not_to include(article3)
      end

      it 'タグに属する記事が複数ある場合、すべて返す' do
        article1 = create(:article)
        article1.tags << tag1
        article2 = create(:article)
        article2.tags << tag1

        result = Article.by_tags([ tag1.id ])

        expect(result).to include(article1, article2)
      end
    end

    context '異常系' do
      it 'タグIDsがnilの場合、全件を返す' do
        create_list(:article, 3)

        result = Article.by_tags(nil)

        expect(result.count).to eq(3)
      end

      it 'タグIDsが空配列の場合、全件を返す' do
        create_list(:article, 3)

        result = Article.by_tags([])

        expect(result.count).to eq(3)
      end

      it '存在しないタグIDの場合、空のリレーションを返す' do
        article = create(:article)
        article.tags << tag1

        result = Article.by_tags([ 99999 ])

        expect(result).to be_empty
      end
    end
  end
end
