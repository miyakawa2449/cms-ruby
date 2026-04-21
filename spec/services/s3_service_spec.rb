require "rails_helper"

RSpec.describe S3Service do
  let(:bucket_name) { "portfolio-backup-miyakawa-codes" }
  let(:mock_client) { instance_double(Aws::S3::Client) }
  let(:service) do
    allow(Aws::S3::Client).to receive(:new).and_return(mock_client)
    described_class.new
  end

  before do
    stub_const("ENV", ENV.to_h.merge(
      "AWS_BACKUP_ACCESS_KEY_ID" => "test_key",
      "AWS_BACKUP_SECRET_ACCESS_KEY" => "test_secret",
      "AWS_BACKUP_REGION" => "ap-northeast-1",
      "S3_BACKUP_BUCKET" => bucket_name
    ))
  end

  describe "#upload" do
    let(:test_file) { Rails.root.join("tmp", "s3_test_upload.txt").to_s }

    before do
      FileUtils.mkdir_p(File.dirname(test_file))
      File.write(test_file, "backup content")
      allow(mock_client).to receive(:put_object)
    end

    after { File.delete(test_file) if File.exist?(test_file) }

    it "calls put_object with correct bucket" do
      expect(mock_client).to receive(:put_object).with(
        hash_including(bucket: bucket_name)
      )
      service.upload(file_path: test_file, backup_type: "daily", category: "database")
    end

    it "enables SSE-S3 encryption" do
      expect(mock_client).to receive(:put_object).with(
        hash_including(server_side_encryption: "AES256")
      )
      service.upload(file_path: test_file, backup_type: "daily", category: "database")
    end

    it "includes required metadata" do
      expect(mock_client).to receive(:put_object).with(
        hash_including(
          metadata: hash_including(
            "backup-type" => "daily",
            "category" => "database",
            "checksum" => be_a(String)
          )
        )
      )
      service.upload(file_path: test_file, backup_type: "daily", category: "database")
    end

    it "generates object key in correct format" do
      returned_key = nil
      allow(mock_client).to receive(:put_object) do |args|
        returned_key = args[:key]
      end

      service.upload(file_path: test_file, backup_type: "daily", category: "database")

      # Format: daily/YYYY/MM/DD/database_filename
      expect(returned_key).to match(%r{\Adaily/\d{4}/\d{2}/\d{2}/database_.+\z})
    end

    it "returns the S3 object key" do
      result = service.upload(file_path: test_file, backup_type: "weekly", category: "storage")
      expect(result).to match(%r{\Aweekly/\d{4}/\d{2}/\d{2}/storage_.+\z})
    end

    it "logs the upload" do
      expect(Rails.logger).to receive(:info).with(/S3Service: uploaded key=/)
      service.upload(file_path: test_file, backup_type: "daily", category: "database")
    end
  end

  describe "#list_backups" do
    let(:mock_object) do
      double(key: "daily/2026/04/20/database_file.dump.gz",
             size: 1024,
             last_modified: Time.current,
             etag: '"abc123"')
    end
    let(:mock_response) { double(contents: [ mock_object ]) }

    before do
      allow(mock_client).to receive(:list_objects_v2).and_return(mock_response)
    end

    it "returns an array of backup objects" do
      result = service.list_backups
      expect(result).to be_an(Array)
      expect(result.first).to include(:key, :size, :last_modified, :etag)
    end

    it "passes backup_type as prefix when specified" do
      expect(mock_client).to receive(:list_objects_v2).with(
        hash_including(prefix: "daily/")
      ).and_return(mock_response)
      service.list_backups(backup_type: "daily")
    end

    it "uses empty prefix when no backup_type given" do
      expect(mock_client).to receive(:list_objects_v2).with(
        hash_including(prefix: "")
      ).and_return(mock_response)
      service.list_backups
    end

    it "filters by category when specified" do
      mock_db = double(key: "daily/2026/04/20/database_file.dump.gz",
                       size: 512, last_modified: Time.current, etag: '"a"')
      mock_st = double(key: "daily/2026/04/20/storage_file.tar.gz",
                       size: 256, last_modified: Time.current, etag: '"b"')
      allow(mock_client).to receive(:list_objects_v2)
        .and_return(double(contents: [ mock_db, mock_st ]))

      result = service.list_backups(backup_type: "daily", category: "database")
      expect(result.map { |o| o[:key] }).to all(include("/database_"))
      expect(result.map { |o| o[:key] }).not_to include(mock_st.key)
    end
  end

  describe "#download" do
    let(:destination) { Rails.root.join("tmp", "s3_test_download.txt").to_s }

    before { allow(mock_client).to receive(:get_object) }
    after { File.delete(destination) if File.exist?(destination) }

    it "calls get_object with correct parameters" do
      expect(mock_client).to receive(:get_object).with(
        bucket: bucket_name,
        key: "daily/2026/04/20/database_file.dump.gz",
        response_target: destination
      )
      service.download(
        object_key: "daily/2026/04/20/database_file.dump.gz",
        destination: destination
      )
    end

    it "creates destination directory if missing" do
      deep_dest = Rails.root.join("tmp", "s3_test_deep", "nested", "file.gz").to_s
      service.download(object_key: "some/key", destination: deep_dest)
      expect(Dir.exist?(File.dirname(deep_dest))).to be true
    ensure
      FileUtils.rm_rf(Rails.root.join("tmp", "s3_test_deep").to_s)
    end

    it "logs the download" do
      expect(Rails.logger).to receive(:info).with(/S3Service: downloaded key=/)
      service.download(
        object_key: "daily/2026/04/20/database_file.dump.gz",
        destination: destination
      )
    end
  end

  describe "#delete" do
    before { allow(mock_client).to receive(:delete_object) }

    it "calls delete_object with correct parameters" do
      expect(mock_client).to receive(:delete_object).with(
        bucket: bucket_name,
        key: "daily/2026/04/20/database_file.dump.gz"
      )
      service.delete(object_key: "daily/2026/04/20/database_file.dump.gz")
    end

    it "logs the deletion" do
      expect(Rails.logger).to receive(:info).with(/S3Service: deleted key=/)
      service.delete(object_key: "daily/2026/04/20/database_file.dump.gz")
    end
  end

  describe "#get_latest_backup_size" do
    it "sums sizes of all backups for the given type" do
      objects = [
        { key: "daily/a", size: 1000, last_modified: Time.current, etag: '"a"' },
        { key: "daily/b", size: 2000, last_modified: Time.current, etag: '"b"' }
      ]
      allow(service).to receive(:list_backups).with(backup_type: "daily").and_return(objects)

      expect(service.get_latest_backup_size("daily")).to eq(3000)
    end

    it "returns 0 when no backups exist" do
      allow(service).to receive(:list_backups).with(backup_type: "daily").and_return([])
      expect(service.get_latest_backup_size("daily")).to eq(0)
    end
  end

  describe "Property 5: S3暗号化アップロード" do
    # Feature: phase-7.3-auto-backup, Property 5: S3暗号化アップロード
    let(:test_file) { Rails.root.join("tmp", "s3_prop5_test.txt").to_s }

    before do
      File.write(test_file, "test")
      allow(mock_client).to receive(:put_object)
    end

    after { File.delete(test_file) if File.exist?(test_file) }

    it "always uploads with SSE-S3 AES256 encryption regardless of backup type" do
      %w[daily weekly monthly].each do |type|
        expect(mock_client).to receive(:put_object).with(
          hash_including(server_side_encryption: "AES256")
        )
        service.upload(file_path: test_file, backup_type: type, category: "database")
      end
    end

    it "always uses correct object key format {backup_type}/{YYYY}/{MM}/{DD}/{category}_{filename}" do
      %w[daily weekly monthly].each do |type|
        returned_key = nil
        allow(mock_client).to receive(:put_object) { |args| returned_key = args[:key] }

        service.upload(file_path: test_file, backup_type: type, category: "storage")

        expect(returned_key).to match(%r{\A#{type}/\d{4}/\d{2}/\d{2}/storage_.+\z}),
          "Key #{returned_key.inspect} did not match expected format for type=#{type}"
      end
    end
  end

  describe "S3 error handling" do
    let(:test_file) { Rails.root.join("tmp", "s3_err_test.txt").to_s }

    before { File.write(test_file, "test") }
    after { File.delete(test_file) if File.exist?(test_file) }

    it "propagates Aws::S3::Errors::ServiceError on upload failure" do
      allow(mock_client).to receive(:put_object)
        .and_raise(Aws::S3::Errors::ServiceError.new(nil, "Access Denied"))

      expect {
        service.upload(file_path: test_file, backup_type: "daily", category: "database")
      }.to raise_error(Aws::S3::Errors::ServiceError)
    end

    it "propagates error on list failure" do
      allow(mock_client).to receive(:list_objects_v2)
        .and_raise(Aws::S3::Errors::ServiceError.new(nil, "NoSuchBucket"))

      expect { service.list_backups }.to raise_error(Aws::S3::Errors::ServiceError)
    end
  end
end
