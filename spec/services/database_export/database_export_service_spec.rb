# frozen_string_literal: true

require "rails_helper"

RSpec.describe DatabaseExport::DatabaseExportService do
  describe "#call" do
    subject(:result) { described_class.new.call }

    before do
      # Create test data
      @admin = create(:admin_user)
      @category = create(:category)
      @tag = create(:tag)
      @article = create(:article, admin_user: @admin)
      @article.categories << @category
      @article.tags << @tag
    end

    it "returns a hash with metadata, models, and active_storage keys" do
      expect(result).to be_a(Hash)
      expect(result.keys).to contain_exactly(:metadata, :models, :active_storage)
    end

    describe "metadata" do
      it "includes exported_at timestamp" do
        expect(result[:metadata][:exported_at]).to be_present
        expect { Time.parse(result[:metadata][:exported_at]) }.not_to raise_error
      end

      it "includes rails_version" do
        expect(result[:metadata][:rails_version]).to eq(Rails.version)
      end

      it "includes ruby_version" do
        expect(result[:metadata][:ruby_version]).to eq(RUBY_VERSION)
      end

      it "includes models_count for each model" do
        expect(result[:metadata][:models_count]).to be_a(Hash)
        expect(result[:metadata][:models_count]["AdminUser"]).to eq(AdminUser.count)
        expect(result[:metadata][:models_count]["Article"]).to eq(Article.count)
        expect(result[:metadata][:models_count]["Category"]).to eq(Category.count)
      end
    end

    describe "models" do
      it "exports all EXPORT_MODELS" do
        expected_models = DatabaseExport::DatabaseExportService::EXPORT_MODELS.map(&:name)
        expect(result[:models].keys).to match_array(expected_models)
      end

      it "exports AdminUser records" do
        admin_users = result[:models]["AdminUser"]
        expect(admin_users).to be_an(Array)
        expect(admin_users.size).to eq(AdminUser.count)
        expect(admin_users.first["email"]).to eq(@admin.email)
      end

      it "exports Article records" do
        articles = result[:models]["Article"]
        expect(articles).to be_an(Array)
        expect(articles.size).to eq(Article.count)
      end

      it "exports ArticleCategory join records" do
        article_categories = result[:models]["ArticleCategory"]
        expect(article_categories).to be_an(Array)
        expect(article_categories.size).to eq(ArticleCategory.count)
      end

      it "exports ArticleTag join records" do
        article_tags = result[:models]["ArticleTag"]
        expect(article_tags).to be_an(Array)
        expect(article_tags.size).to eq(ArticleTag.count)
      end

      it "preserves all record attributes" do
        articles = result[:models]["Article"]
        article_data = articles.find { |a| a["id"] == @article.id }

        expect(article_data["title"]).to eq(@article.title)
        expect(article_data["admin_user_id"]).to eq(@article.admin_user_id)
        expect(article_data["created_at"]).to be_present
      end
    end

    describe "active_storage" do
      it "includes blobs array" do
        expect(result[:active_storage][:blobs]).to be_an(Array)
      end

      it "includes attachments array" do
        expect(result[:active_storage][:attachments]).to be_an(Array)
      end

      context "when there are Active Storage attachments" do
        before do
          # Attach a file to article
          @article.thumbnail_image.attach(
            io: StringIO.new("test image content"),
            filename: "test.jpg",
            content_type: "image/jpeg"
          )
        end

        it "exports blob metadata" do
          blobs = result[:active_storage][:blobs]
          expect(blobs.size).to be >= 1
          expect(blobs.first).to include("key", "filename", "content_type", "byte_size")
        end

        it "exports attachment metadata" do
          attachments = result[:active_storage][:attachments]
          expect(attachments.size).to be >= 1
          expect(attachments.first).to include("name", "record_type", "record_id", "blob_id")
        end
      end
    end
  end
end
