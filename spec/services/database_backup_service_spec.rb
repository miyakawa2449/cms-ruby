require "rails_helper"

RSpec.describe DatabaseBackupService do
  let(:backup_type) { "daily" }
  let(:service) { described_class.new(backup_type) }
  let(:backup_dir) { Rails.root.join("tmp", "backup").to_s }

  after do
    # Clean up any backup files created during tests
    Dir.glob(File.join(backup_dir, "database_*")).each { |f| File.delete(f) if File.exist?(f) }
  end

  # Helper: stub create_dump to write a real file at the service's expected path
  def stub_create_dump(svc, content: "dummy pg_dump output")
    allow(svc).to receive(:create_dump) do
      dump_file = svc.send(:temp_file_path, "database", "dump")
      FileUtils.mkdir_p(File.dirname(dump_file))
      File.write(dump_file, content)
      dump_file
    end
  end

  describe "#execute" do
    context "when pg_dump succeeds" do
      it "returns a compressed .dump.gz file" do
        stub_create_dump(service)
        result = service.execute
        expect(result).to end_with(".dump.gz")
        expect(File.exist?(result)).to be true
      end

      it "generates filename with correct format" do
        stub_create_dump(service)
        result = service.execute
        expect(File.basename(result)).to match(/\Adatabase_\d{8}_\d{6}_daily\.dump\.gz\z/)
      end

      it "creates tmp/backup directory if not present" do
        stub_create_dump(service)
        FileUtils.rm_rf(backup_dir)
        service.execute
        expect(Dir.exist?(backup_dir)).to be true
      end

      it "removes original dump file after compression" do
        original_dump = nil
        allow(service).to receive(:create_dump) do
          dump_file = service.send(:temp_file_path, "database", "dump")
          FileUtils.mkdir_p(File.dirname(dump_file))
          File.write(dump_file, "dummy")
          original_dump = dump_file
          dump_file
        end

        service.execute
        expect(File.exist?(original_dump)).to be false
      end

      it "produces a valid gzip file" do
        stub_create_dump(service, content: "dummy dump content for gzip test")
        result = service.execute
        expect { Zlib::GzipReader.open(result) { |gz| gz.read } }.not_to raise_error
      end

      it "logs the SHA256 checksum" do
        stub_create_dump(service)
        expect(Rails.logger).to receive(:info).with(/checksum=[0-9a-f]{64}/)
        service.execute
      end
    end

    context "when backup_type is weekly" do
      let(:service) { described_class.new("weekly") }

      it "includes backup_type in filename" do
        stub_create_dump(service)
        result = service.execute
        expect(File.basename(result)).to include("weekly")
      end
    end
  end

  describe "#execute (error handling)" do
    context "when pg_dump fails" do
      it "raises an error with exit code information" do
        # Stub build_pg_dump_command to run a command that always fails
        allow(service).to receive(:build_pg_dump_command) do |_db_config, dump_file|
          FileUtils.mkdir_p(File.dirname(dump_file))
          [ "false" ]  # Unix `false` command always exits with code 1
        end

        expect { service.execute }.to raise_error(RuntimeError, /Database dump failed/)
      end
    end
  end

  describe "Property 2: backup file format" do
    # Feature: phase-7.3-auto-backup, Property 2: バックアップファイル形式
    it "generates database backup files matching {category}_{YYYYMMDD}_{HHMMSS}_{backup_type}.dump.gz" do
      %w[daily weekly monthly].each do |type|
        svc = described_class.new(type)
        stub_create_dump(svc)

        result = svc.execute
        expect(File.basename(result)).to match(
          /\Adatabase_\d{8}_\d{6}_#{type}\.dump\.gz\z/
        ), "Expected #{File.basename(result)} to match naming format for type=#{type}"
      end
    end
  end
end
