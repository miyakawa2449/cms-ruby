require "rails_helper"

RSpec.describe ConfigBackupService do
  let(:backup_type) { "daily" }
  let(:service) { described_class.new(backup_type) }
  let(:backup_dir) { Rails.root.join("tmp", "backup").to_s }

  # Use a temp root dir so we never touch real .env or credentials files
  let(:fake_root) { Rails.root.join("tmp", "config_backup_test_root") }

  before do
    FileUtils.mkdir_p(fake_root)
    FileUtils.mkdir_p(File.join(fake_root.to_s, "config"))
    allow(Rails).to receive(:root).and_return(fake_root)
    FileUtils.mkdir_p(backup_dir)
  end

  after do
    FileUtils.rm_rf(fake_root)
    Dir.glob(File.join(backup_dir, "config_*")).each { |f| File.delete(f) if File.exist?(f) }
  end

  def create_required_files
    File.write(File.join(fake_root.to_s, ".env"), "SECRET=abc")
    File.write(File.join(fake_root.to_s, "config", "credentials.yml.enc"), "encrypted_data")
  end

  def create_optional_files
    File.write(File.join(fake_root.to_s, ".env.production"), "PROD_SECRET=xyz")
    File.write(File.join(fake_root.to_s, "config", "master.key"), "masterkey")
  end

  describe "#execute" do
    context "when required files exist" do
      before { create_required_files }

      it "returns a .tar.gz file path" do
        result = service.execute
        expect(result).to end_with(".tar.gz")
        expect(File.exist?(result)).to be true
      end

      it "generates filename with correct format" do
        result = service.execute
        expect(File.basename(result)).to match(/\Aconfig_\d{8}_\d{6}_daily\.tar\.gz\z/)
      end

      it "produces a valid tar.gz archive" do
        result = service.execute
        `tar -tzf #{result} 2>&1`
        expect($?.success?).to be true
      end

      it "includes required files in the archive" do
        result = service.execute
        contents = `tar -tzf #{result}`
        expect(contents).to include(".env")
        expect(contents).to include("credentials.yml.enc")
      end

      it "logs the SHA256 checksum" do
        expect(Rails.logger).to receive(:info).with(/checksum=[0-9a-f]{64}/)
        service.execute
      end

      it "cleans up the staging directory after archiving" do
        service.execute
        staging_dirs = Dir.glob(File.join(backup_dir, "config_staging_*"))
        expect(staging_dirs).to be_empty
      end
    end

    context "when optional files also exist" do
      before do
        create_required_files
        create_optional_files
      end

      it "includes optional files in the archive" do
        result = service.execute
        contents = `tar -tzf #{result}`
        expect(contents).to include(".env.production")
        expect(contents).to include("master.key")
      end
    end

    context "when optional files do not exist" do
      before { create_required_files }

      it "succeeds without optional files" do
        result = service.execute
        expect(File.exist?(result)).to be true
      end

      it "does not raise an error for missing optional files" do
        expect { service.execute }.not_to raise_error
      end
    end

    context "when required files are missing" do
      it "raises an error listing missing files" do
        expect { service.execute }.to raise_error(RuntimeError, /Required config files missing/)
      end

      it "mentions .env in the error when .env is missing" do
        File.write(File.join(fake_root.to_s, "config", "credentials.yml.enc"), "data")
        expect { service.execute }.to raise_error(RuntimeError, /\.env/)
      end

      it "mentions credentials.yml.enc in the error when it is missing" do
        File.write(File.join(fake_root.to_s, ".env"), "SECRET=abc")
        expect { service.execute }.to raise_error(RuntimeError, /credentials\.yml\.enc/)
      end
    end

    context "when backup_type is monthly" do
      let(:service) { described_class.new("monthly") }

      before { create_required_files }

      it "includes backup_type in filename" do
        result = service.execute
        expect(File.basename(result)).to include("monthly")
      end
    end
  end

  describe "Property 2: backup file format" do
    # Feature: phase-7.3-auto-backup, Property 2: バックアップファイル形式
    before { create_required_files }

    it "generates config backup files matching {category}_{YYYYMMDD}_{HHMMSS}_{backup_type}.tar.gz" do
      %w[daily weekly monthly].each do |type|
        svc = described_class.new(type)
        result = svc.execute
        expect(File.basename(result)).to match(
          /\Aconfig_\d{8}_\d{6}_#{type}\.tar\.gz\z/
        ), "Expected #{File.basename(result)} to match naming format for type=#{type}"
      end
    end
  end

  describe "Property 4: 設定ファイル完全性" do
    # Feature: phase-7.3-auto-backup, Property 4: 設定ファイル完全性
    before do
      create_required_files
      create_optional_files
    end

    it "includes all present required and optional files in the archive" do
      result = service.execute
      contents = `tar -tzf #{result}`

      described_class::REQUIRED_FILES.each do |f|
        expect(contents).to include(File.basename(f)),
          "Expected archive to contain required file: #{f}"
      end

      described_class::OPTIONAL_FILES.each do |f|
        expect(contents).to include(File.basename(f)),
          "Expected archive to contain optional file: #{f}"
      end
    end
  end
end
