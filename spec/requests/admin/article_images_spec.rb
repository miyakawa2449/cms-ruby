require 'rails_helper'

RSpec.describe "Admin::ArticleImages", type: :request do
  let(:admin_user) { create(:admin_user) }
  let(:article) { create(:article, admin_user: admin_user) }

  before do
    host! "localhost"
    sign_in admin_user, scope: :admin_user
  end

  describe "POST /admin/articles/:article_id/images" do
    let(:valid_image) do
      Rack::Test::UploadedFile.new(
        Rails.root.join('spec/fixtures/files/test_image.jpg'),
        'image/jpeg'
      )
    end

    context "with valid parameters" do
      it "uploads image successfully" do
        post admin_article_images_path(article_id: article.id), params: {
          image: valid_image,
          alt_text: 'Test image description'
        }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['alt_text']).to eq 'Test image description'
        expect(json['width']).to eq 800
        expect(json['height']).to eq 600
        expect(json['markdown']).to include('![Test image description]')
      end

      it "uploads image with caption successfully" do
        post admin_article_images_path(article_id: article.id), params: {
          image: valid_image,
          alt_text: 'Test image',
          caption: 'This is a caption'
        }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['caption']).to eq 'This is a caption'
        expect(json['markdown']).to include('<figure class="article-image">')
        expect(json['markdown']).to include('<figcaption>This is a caption</figcaption>')
      end

      it "creates MediaMetadata record" do
        expect {
          post admin_article_images_path(article_id: article.id), params: {
            image: valid_image,
            alt_text: 'Test image'
          }
        }.to change(MediaMetadata, :count).by(1)
      end
    end

    context "with invalid parameters" do
      it "returns error when image is missing" do
        post admin_article_images_path(article_id: article.id), params: {
          alt_text: 'Test image'
        }

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['error']).to include('画像ファイルが選択されていません')
      end

      it "returns error when alt_text is missing" do
        post admin_article_images_path(article_id: article.id), params: {
          image: valid_image
        }

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['error']).to include('alt属性は必須です')
      end

      it "returns error for invalid file type" do
        # Create a text file
        file = Tempfile.new([ 'test', '.txt' ])
        file.write('not an image')
        file.rewind
        invalid_file = Rack::Test::UploadedFile.new(file.path, 'text/plain')

        post admin_article_images_path(article_id: article.id), params: {
          image: invalid_file,
          alt_text: 'Test image'
        }

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['error']).to include('対応していないファイル形式')
      end
    end

    context "XSS protection" do
      it "escapes alt_text in HTML output" do
        post admin_article_images_path(article_id: article.id), params: {
          image: valid_image,
          alt_text: '<script>alert("xss")</script>',
          caption: 'Test caption'
        }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['markdown']).not_to include('<script>')
        expect(json['markdown']).to include('&lt;script&gt;')
      end

      it "escapes caption in HTML output" do
        post admin_article_images_path(article_id: article.id), params: {
          image: valid_image,
          alt_text: 'Test image',
          caption: '<script>alert("xss")</script>'
        }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['markdown']).not_to include('<script>alert')
        expect(json['markdown']).to include('&lt;script&gt;')
      end
    end
  end
end
