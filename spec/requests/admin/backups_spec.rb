require "rails_helper"

RSpec.describe "Admin::Backups", type: :request do
  let(:admin_user) { create(:admin_user) }

  let(:sample_backups) do
    [
      { key: "daily/2026/04/20/database_file.dump.gz", size: 1_048_576, last_modified: 1.hour.ago, etag: '"a"' },
      { key: "weekly/2026/04/14/storage_file.tar.gz", size: 5_242_880, last_modified: 2.days.ago, etag: '"b"' },
      { key: "monthly/2026/04/01/config_file.tar.gz", size: 10_240, last_modified: 20.days.ago, etag: '"c"' }
    ]
  end

  before do
    host! "localhost"
    sign_in admin_user, scope: :admin_user
    allow_any_instance_of(Admin::BackupsController).to receive(:verify_two_factor_authentication!)
    allow_any_instance_of(Admin::BackupsController).to receive(:ensure_admin_path_session!)
    allow_any_instance_of(Admin::BackupsController).to receive(:force_logout_if_admin_path_changed!)
  end

  describe "GET /admin/backups" do
    before do
      allow(S3Service).to receive(:new).and_return(
        instance_double(S3Service, list_backups: sample_backups)
      )
    end

    it "returns HTTP 200" do
      get admin_backups_path
      expect(response).to have_http_status(:success)
    end

    it "displays backup file entries" do
      get admin_backups_path
      expect(response.body).to include("database_file.dump.gz")
      expect(response.body).to include("storage_file.tar.gz")
    end

    it "sorts backups by last_modified descending (newest first)" do
      get admin_backups_path
      body = response.body
      daily_pos   = body.index("database_file.dump.gz")
      weekly_pos  = body.index("storage_file.tar.gz")
      monthly_pos = body.index("config_file.tar.gz")
      expect(daily_pos).to be < weekly_pos
      expect(weekly_pos).to be < monthly_pos
    end

    context "with backup_type filter" do
      it "passes backup_type to S3Service" do
        mock_s3 = instance_double(S3Service, list_backups: sample_backups.first(1))
        expect(S3Service).to receive(:new).and_return(mock_s3)
        expect(mock_s3).to receive(:list_backups).with(backup_type: "daily")

        get admin_backups_path, params: { backup_type: "daily" }
      end

      it "shows the filter form with backup_type options" do
        get admin_backups_path
        expect(response.body).to include("daily")
        expect(response.body).to include("weekly")
        expect(response.body).to include("monthly")
      end
    end

    context "when S3 returns an error" do
      before do
        allow(S3Service).to receive(:new).and_return(
          instance_double(S3Service).tap do |s3|
            allow(s3).to receive(:list_backups)
              .and_raise(Aws::S3::Errors::ServiceError.new(nil, "Access Denied"))
          end
        )
      end

      it "still returns HTTP 200 (does not crash)" do
        get admin_backups_path
        expect(response).to have_http_status(:success)
      end

      it "shows an error message" do
        get admin_backups_path
        expect(response.body).to include("バックアップ一覧の取得に失敗しました")
      end

      it "renders empty backup list" do
        get admin_backups_path
        expect(response.body).to include("バックアップファイルが見つかりませんでした")
      end
    end
  end

  describe "Property 18: バックアップ一覧ソート" do
    # Feature: phase-7.3-auto-backup, Property 18: バックアップ一覧ソート
    it "always displays backups in newest-first order" do
      shuffled = sample_backups.shuffle
      allow(S3Service).to receive(:new).and_return(
        instance_double(S3Service, list_backups: shuffled)
      )

      get admin_backups_path
      body = response.body

      daily_pos   = body.index("database_file.dump.gz")
      weekly_pos  = body.index("storage_file.tar.gz")
      monthly_pos = body.index("config_file.tar.gz")

      expect(daily_pos).to be < weekly_pos
      expect(weekly_pos).to be < monthly_pos
    end
  end

  describe "Property 19: バックアップフィルタリング" do
    # Feature: phase-7.3-auto-backup, Property 19: バックアップフィルタリング
    it "passes the selected type to S3Service as prefix filter" do
      %w[daily weekly monthly].each do |type|
        mock_s3 = instance_double(S3Service, list_backups: [])
        expect(S3Service).to receive(:new).and_return(mock_s3)
        expect(mock_s3).to receive(:list_backups).with(backup_type: type)

        get admin_backups_path, params: { backup_type: type }
      end
    end
  end

  describe "POST /admin/backups/restore" do
    let(:backup_key) { "daily/2026/04/20/database_file.dump.gz" }

    let(:day_files) do
      [
        { key: "daily/2026/04/20/database_file.dump.gz", size: 1024, last_modified: 1.hour.ago, etag: '"a"' },
        { key: "daily/2026/04/20/storage_file.tar.gz",   size: 2048, last_modified: 1.hour.ago, etag: '"b"' },
        { key: "daily/2026/04/20/config_file.tar.gz",    size: 512,  last_modified: 1.hour.ago, etag: '"c"' }
      ]
    end

    # S3Service.new calls ENV.fetch which raises KeyError without credentials.
    # Stub the class method :new to return a mock that bypasses the initializer.
    let(:mock_s3) { double("S3Service", list_backups: day_files) }

    before do
      allow(S3Service).to receive(:new).and_return(mock_s3)
      allow(Restore::RestoreJob).to receive(:perform_later)
    end

    it "redirects to backups index" do
      post restore_admin_backups_path, params: { backup_key: backup_key }
      expect(response).to redirect_to(admin_backups_path)
    end

    it "enqueues Restore::RestoreJob" do
      expect(Restore::RestoreJob).to receive(:perform_later)
      post restore_admin_backups_path, params: { backup_key: backup_key }
    end

    it "passes all three category keys to the job" do
      received_args = nil
      allow(Restore::RestoreJob).to receive(:perform_later) { |args| received_args = args }

      post restore_admin_backups_path, params: { backup_key: backup_key }

      expect(received_args).to be_a(Hash)
      expect(received_args["database"]).to eq("daily/2026/04/20/database_file.dump.gz")
      expect(received_args["storage"]).to eq("daily/2026/04/20/storage_file.tar.gz")
      expect(received_args["config"]).to eq("daily/2026/04/20/config_file.tar.gz")
    end

    it "sets a success flash notice" do
      post restore_admin_backups_path, params: { backup_key: backup_key }
      expect(flash[:notice]).to include("復元ジョブをキューに追加しました")
    end

    context "when backup_key is blank" do
      it "redirects with an alert" do
        post restore_admin_backups_path, params: { backup_key: "" }
        expect(response).to redirect_to(admin_backups_path)
        expect(flash[:alert]).to include("バックアップキーが指定されていません")
      end

      it "does not enqueue the job" do
        expect(Restore::RestoreJob).not_to receive(:perform_later)
        post restore_admin_backups_path, params: { backup_key: "" }
      end
    end

    context "when S3 raises an error" do
      before do
        allow(S3Service).to receive(:new).and_raise(
          Aws::S3::Errors::ServiceError.new(nil, "Access Denied")
        )
      end

      it "redirects with an error message" do
        post restore_admin_backups_path, params: { backup_key: backup_key }
        expect(response).to redirect_to(admin_backups_path)
        expect(flash[:alert]).to include("復元の開始に失敗しました")
      end

      it "does not enqueue the job" do
        expect(Restore::RestoreJob).not_to receive(:perform_later)
        post restore_admin_backups_path, params: { backup_key: backup_key }
      end
    end
  end
end
