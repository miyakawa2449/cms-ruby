# frozen_string_literal: true

require "rails_helper"
require "zip"

RSpec.describe "Admin::Database", type: :request do
  let(:admin_user) { create(:admin_user) }

  describe "GET /admin/database/export" do
    context "when not authenticated" do
      it "redirects to login page" do
        get export_admin_database_path
        expect(response).to redirect_to(new_admin_user_session_path)
      end
    end

    context "when authenticated" do
      before do
        sign_in admin_user, scope: :admin_user

        # Create some test data
        @category = create(:category)
        @tag = create(:tag)
        @article = create(:article, admin_user: admin_user)
        @article.categories << @category
        @article.tags << @tag
      end

      it "returns a ZIP file" do
        get export_admin_database_path

        expect(response).to have_http_status(:success)
        expect(response.content_type).to eq("application/zip")
      end

      it "sets the correct filename in Content-Disposition header" do
        get export_admin_database_path

        content_disposition = response.headers["Content-Disposition"]
        expect(content_disposition).to include("attachment")
        expect(content_disposition).to include("database_export_")
        expect(content_disposition).to include(".zip")
      end

      it "generates a valid ZIP file with data.json" do
        get export_admin_database_path

        # Write response body to a temp file
        temp_zip = Tempfile.new([ "export", ".zip" ])
        temp_zip.binmode
        temp_zip.write(response.body)
        temp_zip.rewind

        # Verify ZIP structure
        Zip::File.open(temp_zip.path) do |zipfile|
          # Check data.json exists
          data_entry = zipfile.find_entry("data.json")
          expect(data_entry).to be_present

          # Parse and verify data.json contents
          json_content = zipfile.read(data_entry)
          data = JSON.parse(json_content)

          expect(data["metadata"]).to be_present
          expect(data["metadata"]["exported_at"]).to be_present
          expect(data["metadata"]["rails_version"]).to eq(Rails.version)
          expect(data["models"]).to be_present
          expect(data["models"]["AdminUser"]).to be_an(Array)
          expect(data["models"]["Article"]).to be_an(Array)
          expect(data["active_storage"]).to be_present
        end

        temp_zip.close
        temp_zip.unlink
      end

      it "includes all model data in the export" do
        get export_admin_database_path

        temp_zip = Tempfile.new([ "export", ".zip" ])
        temp_zip.binmode
        temp_zip.write(response.body)
        temp_zip.rewind

        Zip::File.open(temp_zip.path) do |zipfile|
          data_entry = zipfile.find_entry("data.json")
          data = JSON.parse(zipfile.read(data_entry))

          # Verify model counts match database
          expect(data["metadata"]["models_count"]["AdminUser"]).to eq(AdminUser.count)
          expect(data["metadata"]["models_count"]["Article"]).to eq(Article.count)
          expect(data["metadata"]["models_count"]["Category"]).to eq(Category.count)
          expect(data["metadata"]["models_count"]["Tag"]).to eq(Tag.count)

          # Verify join tables are included
          expect(data["models"]["ArticleCategory"]).to be_present
          expect(data["models"]["ArticleTag"]).to be_present
        end

        temp_zip.close
        temp_zip.unlink
      end

      it "logs the export action" do
        expect(Rails.logger).to receive(:info).with(/Export started by #{admin_user.email}/).at_least(:once)
        allow(Rails.logger).to receive(:info).and_call_original

        get export_admin_database_path
      end
    end

    context "when export fails" do
      before do
        sign_in admin_user, scope: :admin_user
        allow_any_instance_of(DatabaseExport::DatabaseExportService)
          .to receive(:call)
          .and_raise(StandardError, "Test error")
      end

      it "redirects to dashboard with error message" do
        get export_admin_database_path

        expect(response).to redirect_to(admin_dashboard_path)
        follow_redirect!
        expect(response.body).to include("エクスポートに失敗しました")
      end

      it "logs the error" do
        allow(Rails.logger).to receive(:info)
        expect(Rails.logger).to receive(:error).with(/Export failed: Test error/).at_least(:once)
        allow(Rails.logger).to receive(:error).and_call_original

        get export_admin_database_path
      end
    end
  end

  describe "GET /admin/database/import_form" do
    context "when not authenticated" do
      it "redirects to login page" do
        get import_form_admin_database_path
        expect(response).to redirect_to(new_admin_user_session_path)
      end
    end

    context "when authenticated" do
      before do
        sign_in admin_user, scope: :admin_user
        create(:article, admin_user: admin_user)
        create(:category)
      end

      it "returns success" do
        get import_form_admin_database_path
        expect(response).to have_http_status(:success)
      end

      it "displays the import form" do
        get import_form_admin_database_path
        expect(response.body).to include("データベースインポート")
        expect(response.body).to include("ZIPファイルをアップロード")
      end

      it "shows current data counts" do
        get import_form_admin_database_path
        expect(response.body).to include("現在のデータ状況")
      end

      it "shows warning about data deletion" do
        get import_form_admin_database_path
        expect(response.body).to include("既存のデータは全て削除されます")
      end
    end
  end

  describe "POST /admin/database/import" do
    context "when not authenticated" do
      it "redirects to login page" do
        post import_admin_database_path
        expect(response).to redirect_to(new_admin_user_session_path)
      end
    end

    context "when authenticated" do
      before do
        sign_in admin_user, scope: :admin_user
      end

      context "without file" do
        it "redirects with error message" do
          post import_admin_database_path

          expect(response).to redirect_to(import_form_admin_database_path)
          follow_redirect!
          expect(response.body).to include("ZIPファイルを選択してください")
        end
      end

      context "with valid ZIP file" do
        let(:temp_zip_path) { Tempfile.new([ "test", ".zip" ]).path }

        before do
          # Create export data first
          @original_admin = create(:admin_user, email: "export_admin@example.com")
          @original_category = create(:category, name: "Export Category")
          @original_article = create(:article, admin_user: @original_admin, title: "Export Article")
          @original_article.categories << @original_category

          # Export to ZIP
          export_data = DatabaseExport::DatabaseExportService.new.call
          temp_dir = Dir.mktmpdir
          File.write(File.join(temp_dir, "data.json"), JSON.generate(export_data))

          Zip::File.open(temp_zip_path, Zip::File::CREATE) do |zipfile|
            zipfile.add("data.json", File.join(temp_dir, "data.json"))
          end

          FileUtils.rm_rf(temp_dir)

          # Clear database
          AiGeneration.delete_all
          MediaMetadata.delete_all
          ActiveStorage::Attachment.delete_all
          ActiveStorage::Blob.delete_all
          ArticleTag.delete_all
          ArticleCategory.delete_all
          Article.delete_all
          Category.delete_all
          # Keep test admin_user for authentication
        end

        after do
          FileUtils.rm_f(temp_zip_path)
        end

        it "imports data and redirects to dashboard" do
          zip_file = Rack::Test::UploadedFile.new(temp_zip_path, "application/zip")

          post import_admin_database_path, params: { zip_file: zip_file }

          expect(response).to redirect_to(admin_dashboard_path)
          # Note: Can't follow_redirect! here because session may be invalidated
          # after import (admin_user is replaced). Check flash directly instead.
          expect(flash[:notice]).to include("インポートが完了しました")
        end

        it "restores model records" do
          zip_file = Rack::Test::UploadedFile.new(temp_zip_path, "application/zip")

          post import_admin_database_path, params: { zip_file: zip_file }

          # Verify data was imported (note: counts may vary due to test setup)
          expect(Category.where(name: "Export Category")).to exist
          expect(Article.where(title: "Export Article")).to exist
        end

        it "resets admin passwords" do
          zip_file = Rack::Test::UploadedFile.new(temp_zip_path, "application/zip")

          post import_admin_database_path, params: { zip_file: zip_file }

          imported_admin = AdminUser.find_by(email: "export_admin@example.com")
          expect(imported_admin).to be_present
          expect(imported_admin.valid_password?("password123")).to be true
        end
      end

      context "with invalid ZIP file" do
        it "redirects with error message" do
          # Create invalid file
          invalid_file = Tempfile.new([ "invalid", ".zip" ])
          invalid_file.write("not a zip file")
          invalid_file.rewind

          zip_file = Rack::Test::UploadedFile.new(invalid_file.path, "application/zip")

          post import_admin_database_path, params: { zip_file: zip_file }

          expect(response).to redirect_to(import_form_admin_database_path)
          follow_redirect!
          expect(response.body).to include("無効なZIPファイルです")

          invalid_file.close
          invalid_file.unlink
        end
      end

      context "with ZIP missing data.json" do
        it "redirects with error message" do
          temp_zip_path = Tempfile.new([ "missing", ".zip" ]).path

          Zip::File.open(temp_zip_path, Zip::File::CREATE) do |zipfile|
            zipfile.get_output_stream("other.txt") { |f| f.write("content") }
          end

          zip_file = Rack::Test::UploadedFile.new(temp_zip_path, "application/zip")

          post import_admin_database_path, params: { zip_file: zip_file }

          expect(response).to redirect_to(import_form_admin_database_path)
          follow_redirect!
          expect(response.body).to include("data.jsonファイルが見つかりません")

          FileUtils.rm_f(temp_zip_path)
        end
      end
    end
  end
end
