# frozen_string_literal: true

require "rails_helper"

RSpec.describe DatabaseImport::DatabaseImportService do
  describe "#call" do
    let(:temp_dir) { Dir.mktmpdir }
    let(:data_json_path) { File.join(temp_dir, "data.json") }

    after do
      FileUtils.rm_rf(temp_dir)
    end

    context "with valid export data" do
      before do
        # Create export data using the export service
        @admin = create(:admin_user, email: "original@example.com")
        @category = create(:category, name: "Test Category")
        @tag = create(:tag, name: "Test Tag")
        @article = create(:article, admin_user: @admin, title: "Test Article")
        @article.categories << @category
        @article.tags << @tag

        # Export data
        export_data = DatabaseExport::DatabaseExportService.new.call
        File.write(data_json_path, JSON.generate(export_data))

        # Clear the database to simulate import into empty database
        ArticleTag.delete_all
        ArticleCategory.delete_all
        Article.delete_all
        AiGeneration.delete_all
        MediaMetadata.delete_all
        ActiveStorage::Attachment.delete_all
        ActiveStorage::Blob.delete_all
        Tag.delete_all
        Category.delete_all
        AdminUser.delete_all
      end

      it "returns success result" do
        result = described_class.new(data_json_path).call

        expect(result[:success]).to be true
        expect(result[:imported]).to be_a(Hash)
      end

      it "clears the application cache after import" do
        # 監査M-2の回帰テスト: insertベースのリストアはモデルのコールバックを
        # 経由しないため、キャッシュを明示的にクリアしないと旧サイト設定や
        # 旧記事一覧が表示され続ける
        # （test環境はnull_storeのため、実際に保存できるMemoryStoreに差し替えて検証）
        memory_store = ActiveSupport::Cache::MemoryStore.new
        allow(Rails).to receive(:cache).and_return(memory_store)
        Rails.cache.write("site_settings_all", "stale-value")

        described_class.new(data_json_path).call

        expect(Rails.cache.exist?("site_settings_all")).to be false
      end

      it "imports all model records" do
        described_class.new(data_json_path).call

        # In test environment, default admin user is created
        expect(AdminUser.count).to be >= 2 # Imported admin + default admin
        expect(Category.find_by(name: "Test Category")).to be_present
        expect(Tag.find_by(name: "Test Tag")).to be_present
        expect(Article.find_by(title: "Test Article")).to be_present
        expect(ArticleCategory.count).to be >= 1
        expect(ArticleTag.count).to be >= 1
      end

      it "preserves original record data" do
        described_class.new(data_json_path).call

        admin = AdminUser.find_by(email: "original@example.com")
        expect(admin.email).to eq("original@example.com")

        category = Category.find_by(name: "Test Category")
        expect(category.name).to eq("Test Category")

        article = Article.find_by(title: "Test Article")
        expect(article.title).to eq("Test Article")
      end

      it "restores associations" do
        described_class.new(data_json_path).call

        article = Article.find_by(title: "Test Article")
        expect(article.categories.map(&:name)).to include("Test Category")
        expect(article.tags.map(&:name)).to include("Test Tag")
      end

      it "resets admin passwords to default" do
        described_class.new(data_json_path).call

        admin = AdminUser.find_by(email: "original@example.com")
        expect(admin.valid_password?(DatabaseImport::DatabaseImportService.admin_reset_password)).to be true
      end

      it "updates category article counts" do
        described_class.new(data_json_path).call

        category = Category.find_by(name: "Test Category")
        expect(category.article_count).to eq(1)
      end

      it "logs import progress" do
        allow(Rails.logger).to receive(:info).and_call_original
        expect(Rails.logger).to receive(:info).with(/Starting database import/).at_least(:once)

        described_class.new(data_json_path).call
      end
    end

    context "with invalid data.json structure" do
      before do
        File.write(data_json_path, JSON.generate({ invalid: "structure" }))
      end

      it "raises ImportError" do
        expect { described_class.new(data_json_path).call }.to raise_error(
          DatabaseImport::DatabaseImportService::ImportError,
          /data.jsonの構造が不正です/
        )
      end
    end

    context "with nonexistent file" do
      it "raises error" do
        expect { described_class.new("/nonexistent/path.json").call }.to raise_error(
          DatabaseImport::DatabaseImportService::ImportError
        )
      end
    end

    context "transaction rollback on error" do
      before do
        # Create valid export data
        @admin = create(:admin_user)
        export_data = DatabaseExport::DatabaseExportService.new.call
        File.write(data_json_path, JSON.generate(export_data))

        # Clear database
        AiGeneration.delete_all
        MediaMetadata.delete_all
        ActiveStorage::Attachment.delete_all
        ActiveStorage::Blob.delete_all
        ArticleTag.delete_all
        ArticleCategory.delete_all
        Article.delete_all
        AdminUser.delete_all
      end

      it "rolls back all changes on error" do
        # Sabotage the import to cause an error mid-transaction
        allow_any_instance_of(described_class)
          .to receive(:reset_admin_passwords)
          .and_raise(StandardError, "Simulated error")

        initial_count = AdminUser.count

        expect { described_class.new(data_json_path).call }.to raise_error(
          DatabaseImport::DatabaseImportService::ImportError
        )

        # Verify rollback - count should remain the same
        expect(AdminUser.count).to eq(initial_count)
      end
    end

    context "clears existing data before import" do
      before do
        # Create export data with one admin
        @export_admin = create(:admin_user, email: "export@example.com")
        export_data = DatabaseExport::DatabaseExportService.new.call
        File.write(data_json_path, JSON.generate(export_data))

        # Create additional admin that should be deleted during import
        AiGeneration.delete_all
        MediaMetadata.delete_all
        ActiveStorage::Attachment.delete_all
        ActiveStorage::Blob.delete_all
        ArticleTag.delete_all
        ArticleCategory.delete_all
        Article.delete_all
        AdminUser.delete_all
        create(:admin_user, email: "existing@example.com")
      end

      it "removes existing records and imports new ones" do
        described_class.new(data_json_path).call

        # In test environment, default admin user is created
        expect(AdminUser.find_by(email: "export@example.com")).to be_present
        expect(AdminUser.find_by(email: TestCredentials.admin_email)).to be_present
        expect(AdminUser.where(email: "existing@example.com")).to be_empty
      end
    end
  end
end
