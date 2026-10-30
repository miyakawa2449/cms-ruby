# frozen_string_literal: true

require "rails_helper"
require "zip"

RSpec.describe DatabaseImport::ZipExtractorService do
  describe "#call" do
    # Tempfile オブジェクトを保持しておかないと、GC の finalizer でファイルが途中で消えることがある
    let(:temp_zip) { Tempfile.new([ "test", ".zip" ]) }
    let(:temp_zip_path) { temp_zip.path }

    after do
      temp_zip.close!
    end

    context "with a valid ZIP file containing data.json" do
      before do
        create_valid_zip(temp_zip_path)
      end

      it "returns the path to the extracted directory" do
        service = described_class.new(temp_zip_path)
        result = service.call

        expect(result).to be_a(String)
        expect(File.directory?(result)).to be true

        # Cleanup
        service.cleanup
      end

      it "extracts data.json" do
        service = described_class.new(temp_zip_path)
        result = service.call

        data_json_path = File.join(result, "data.json")
        expect(File.exist?(data_json_path)).to be true

        data = JSON.parse(File.read(data_json_path))
        expect(data["metadata"]).to be_present

        # Cleanup
        service.cleanup
      end

      it "extracts storage directory if present" do
        # Create ZIP with storage
        create_valid_zip_with_storage(temp_zip_path)

        service = described_class.new(temp_zip_path)
        result = service.call

        storage_path = File.join(result, "storage", "test_file.txt")
        expect(File.exist?(storage_path)).to be true

        # Cleanup
        service.cleanup
      end

      it "logs extraction progress" do
        service = described_class.new(temp_zip_path)

        expect(Rails.logger).to receive(:info).with(/Starting ZIP extraction/).ordered
        allow(Rails.logger).to receive(:info).and_call_original

        result = service.call
        service.cleanup
      end
    end

    context "with a missing ZIP file" do
      it "raises InvalidZipError" do
        service = described_class.new("/nonexistent/path.zip")

        expect { service.call }.to raise_error(
          DatabaseImport::ZipExtractorService::InvalidZipError,
          /ZIPファイルが見つかりません/
        )
      end
    end

    context "with an empty ZIP file" do
      before do
        File.write(temp_zip_path, "")
      end

      it "raises InvalidZipError" do
        service = described_class.new(temp_zip_path)

        expect { service.call }.to raise_error(
          DatabaseImport::ZipExtractorService::InvalidZipError,
          /ZIPファイルが空です/
        )
      end
    end

    context "with an invalid ZIP file" do
      before do
        File.write(temp_zip_path, "not a zip file content")
      end

      it "raises InvalidZipError" do
        service = described_class.new(temp_zip_path)

        expect { service.call }.to raise_error(
          DatabaseImport::ZipExtractorService::InvalidZipError,
          /無効なZIPファイルです/
        )
      end
    end

    context "with a ZIP file missing data.json" do
      before do
        create_zip_without_data_json(temp_zip_path)
      end

      it "raises MissingDataJsonError" do
        service = described_class.new(temp_zip_path)

        expect { service.call }.to raise_error(
          DatabaseImport::ZipExtractorService::MissingDataJsonError,
          /data.jsonファイルが見つかりません/
        )
      end
    end

    context "with a ZIP file containing invalid JSON" do
      before do
        create_zip_with_invalid_json(temp_zip_path)
      end

      it "raises InvalidZipError" do
        service = described_class.new(temp_zip_path)

        expect { service.call }.to raise_error(
          DatabaseImport::ZipExtractorService::InvalidZipError,
          /data.jsonの形式が不正です/
        )
      end
    end

    context "with a ZIP file containing a path traversal entry" do
      let(:outside_path) { File.join(Dir.tmpdir, "zip_traversal_#{SecureRandom.hex(4)}.txt") }

      before do
        create_zip_with_traversal_entry(temp_zip_path, "../#{File.basename(outside_path)}")
      end

      after do
        FileUtils.rm_f(outside_path)
      end

      it "raises InvalidZipError without writing outside the temp directory" do
        service = described_class.new(temp_zip_path)

        expect { service.call }.to raise_error(
          DatabaseImport::ZipExtractorService::InvalidZipError,
          /不正なファイルパスが含まれています/
        )
        expect(File.exist?(outside_path)).to be false
      end
    end
  end

  describe "#cleanup" do
    # Tempfile オブジェクトを保持しておかないと、GC の finalizer でファイルが途中で消えることがある
    let(:temp_zip) { Tempfile.new([ "test", ".zip" ]) }
    let(:temp_zip_path) { temp_zip.path }

    before do
      create_valid_zip(temp_zip_path)
    end

    after do
      temp_zip.close!
    end

    it "removes the temporary directory" do
      service = described_class.new(temp_zip_path)
      extracted_dir = service.call

      expect(File.exist?(extracted_dir)).to be true

      service.cleanup

      expect(File.exist?(extracted_dir)).to be false
    end
  end

  # Helper methods to create test ZIP files
  def create_valid_zip(path)
    Zip::File.open(path, create: true) do |zipfile|
      data = {
        metadata: { exported_at: Time.current.iso8601 },
        models: {},
        active_storage: { blobs: [], attachments: [] }
      }
      zipfile.get_output_stream("data.json") { |f| f.write(JSON.generate(data)) }
    end
  end

  def create_valid_zip_with_storage(path)
    Zip::File.open(path, create: true) do |zipfile|
      data = {
        metadata: { exported_at: Time.current.iso8601 },
        models: {},
        active_storage: { blobs: [], attachments: [] }
      }
      zipfile.get_output_stream("data.json") { |f| f.write(JSON.generate(data)) }
      zipfile.get_output_stream("storage/test_file.txt") { |f| f.write("test content") }
    end
  end

  def create_zip_without_data_json(path)
    Zip::File.open(path, create: true) do |zipfile|
      zipfile.get_output_stream("other_file.txt") { |f| f.write("content") }
    end
  end

  def create_zip_with_invalid_json(path)
    Zip::File.open(path, create: true) do |zipfile|
      zipfile.get_output_stream("data.json") { |f| f.write("not valid json {{{") }
    end
  end

  def create_zip_with_traversal_entry(path, entry_name)
    Zip::OutputStream.open(path) do |zos|
      zos.put_next_entry("data.json")
      zos.write(JSON.generate({ models: {} }))
      zos.put_next_entry(entry_name)
      zos.write("malicious")
    end
  end
end
