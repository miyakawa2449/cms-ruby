require "rails_helper"

RSpec.describe StorageBackupService do
  # 重要: このspecは storage/ の削除・作成を伴う破壊的なセットアップを含む。
  # 実リポジトリのstorage/（devの実画像）を壊さないよう、必ず一時ディレクトリを
  # Rails.root に差し替えてテストする（StorageRestoreService specと同じ隔離パターン）。
  # 2026-07-16: 未隔離だったこのspecがdev環境の実画像を削除する事故が発生（S1-7で修正）
  let(:fake_root) { Pathname.new(Dir.mktmpdir("storage_backup_spec_")) }
  let(:backup_type) { "daily" }
  let(:service) { described_class.new(backup_type) }
  let(:backup_dir) { fake_root.join("tmp", "backup").to_s }
  let(:storage_dir) { fake_root.join("storage").to_s }

  before do
    allow(Rails).to receive(:root).and_return(fake_root)
  end

  after { FileUtils.rm_rf(fake_root) }

  describe "#execute" do
    context "when storage/ directory exists" do
      before do
        FileUtils.mkdir_p(storage_dir)
      end

      it "returns a .tar.gz file path" do
        result = service.execute
        expect(result).to end_with(".tar.gz")
        expect(File.exist?(result)).to be true
      end

      it "generates filename with correct format" do
        result = service.execute
        expect(File.basename(result)).to match(/\Astorage_\d{8}_\d{6}_daily\.tar\.gz\z/)
      end

      it "produces a valid tar.gz archive" do
        result = service.execute
        # Verify it can be listed without errors
        output = `tar -tzf #{result} 2>&1`
        expect($?.success?).to be true
      end

      it "logs the SHA256 checksum" do
        expect(Rails.logger).to receive(:info).with(/checksum=[0-9a-f]{64}/)
        service.execute
      end

      context "when storage/ has files" do
        let(:test_file) { File.join(storage_dir, "test_image.png") }

        before do
          File.write(test_file, "fake image data")
        end

        it "includes files from storage/ in the archive" do
          result = service.execute
          contents = `tar -tzf #{result}`
          expect(contents).to include("test_image.png")
        end
      end
    end

    context "when storage/ directory does not exist" do
      # fake_root配下にstorage/を作らないだけでよい（実storageは絶対に消さない）

      it "logs a warning" do
        expect(Rails.logger).to receive(:warn).with(/storage\/ directory not found/)
        service.execute
      end

      it "creates an archive anyway (empty archive)" do
        allow(Rails.logger).to receive(:warn)
        result = service.execute
        expect(File.exist?(result)).to be true
      end

      it "produces a valid (possibly empty) tar.gz archive" do
        allow(Rails.logger).to receive(:warn)
        result = service.execute
        expect($?).to be_nil.or(satisfy { `tar -tzf #{result} 2>&1`; $?.success? })
        # Simply verify the file is a valid gzip
        expect { Zlib::GzipReader.open(result) { |gz| gz.read } }.not_to raise_error
      end
    end

    context "when backup_type is weekly" do
      let(:service) { described_class.new("weekly") }

      before { FileUtils.mkdir_p(storage_dir) }

      it "includes backup_type in filename" do
        result = service.execute
        expect(File.basename(result)).to include("weekly")
      end
    end

    context "when tar command fails" do
      before { FileUtils.mkdir_p(storage_dir) }

      it "raises an error" do
        allow(service).to receive(:system).and_return(false)
        status_double = instance_double(Process::Status, success?: false, exitstatus: 1)
        allow(Process).to receive(:last_status).and_return(status_double)

        expect { service.execute }.to raise_error(RuntimeError, /Storage archive failed/)
      end
    end
  end

  describe "Property 2: backup file format" do
    # Feature: phase-7.3-auto-backup, Property 2: バックアップファイル形式
    before { FileUtils.mkdir_p(storage_dir) }

    it "generates storage backup files matching {category}_{YYYYMMDD}_{HHMMSS}_{backup_type}.tar.gz" do
      %w[daily weekly monthly].each do |type|
        svc = described_class.new(type)
        result = svc.execute
        expect(File.basename(result)).to match(
          /\Astorage_\d{8}_\d{6}_#{type}\.tar\.gz\z/
        ), "Expected #{File.basename(result)} to match naming format for type=#{type}"
      end
    end
  end
end
