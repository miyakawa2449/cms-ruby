# frozen_string_literal: true

require "rails_helper"
require "zip"

RSpec.describe DatabaseExport::ZipGeneratorService do
  describe "#call" do
    let(:temp_dir) { Dir.mktmpdir }
    let(:export_data) do
      {
        metadata: {
          exported_at: Time.current.iso8601,
          rails_version: Rails.version,
          ruby_version: RUBY_VERSION,
          models_count: { "Article" => 5, "Category" => 3 }
        },
        models: {
          "Article" => [ { "id" => 1, "title" => "Test Article" } ],
          "Category" => [ { "id" => 1, "name" => "Test Category" } ]
        },
        active_storage: {
          blobs: [],
          attachments: []
        }
      }
    end

    subject(:service) { described_class.new(temp_dir, export_data) }

    after do
      FileUtils.rm_rf(temp_dir)
    end

    it "returns the path to the generated ZIP file" do
      result = service.call
      expect(result).to be_a(String)
      expect(result).to end_with(".zip")
      expect(File.exist?(result)).to be true

      # Clean up
      FileUtils.rm_f(result)
    end

    it "creates a valid ZIP file" do
      zip_path = service.call

      expect { Zip::File.open(zip_path) {} }.not_to raise_error

      # Clean up
      FileUtils.rm_f(zip_path)
    end

    it "includes data.json in the ZIP" do
      zip_path = service.call

      Zip::File.open(zip_path) do |zipfile|
        expect(zipfile.find_entry("data.json")).to be_present
      end

      # Clean up
      FileUtils.rm_f(zip_path)
    end

    it "data.json contains the export data" do
      zip_path = service.call

      Zip::File.open(zip_path) do |zipfile|
        entry = zipfile.find_entry("data.json")
        json_content = zipfile.read(entry)
        parsed_data = JSON.parse(json_content)

        expect(parsed_data["metadata"]["rails_version"]).to eq(Rails.version)
        expect(parsed_data["models"]["Article"]).to be_an(Array)
        expect(parsed_data["models"]["Article"].first["title"]).to eq("Test Article")
      end

      # Clean up
      FileUtils.rm_f(zip_path)
    end

    context "when storage files exist" do
      before do
        # Create a storage directory with a file
        storage_dir = File.join(temp_dir, "storage", "ab", "cd")
        FileUtils.mkdir_p(storage_dir)
        File.write(File.join(storage_dir, "test_blob.txt"), "blob content")
      end

      it "includes storage files in the ZIP" do
        zip_path = service.call

        Zip::File.open(zip_path) do |zipfile|
          entry = zipfile.find_entry("storage/ab/cd/test_blob.txt")
          expect(entry).to be_present
          expect(zipfile.read(entry)).to eq("blob content")
        end

        # Clean up
        FileUtils.rm_f(zip_path)
      end
    end

    it "generates a unique filename with timestamp" do
      zip_path = service.call
      filename = File.basename(zip_path)

      expect(filename).to match(/^database_export_\d{8}_\d{6}\.zip$/)

      # Clean up
      FileUtils.rm_f(zip_path)
    end

    it "logs ZIP generation progress" do
      allow(Rails.logger).to receive(:info).and_call_original

      expect(Rails.logger).to receive(:info).with(/Starting ZIP generation/).ordered
      expect(Rails.logger).to receive(:info).with(/data\.json written/).ordered
      expect(Rails.logger).to receive(:info).with(/ZIP contains/).ordered
      expect(Rails.logger).to receive(:info).with(/ZIP file created/).ordered

      zip_path = service.call

      # Clean up
      FileUtils.rm_f(zip_path)
    end

    context "when an error occurs" do
      before do
        allow(File).to receive(:write).and_raise(Errno::ENOSPC, "No space left on device")
        allow(Rails.logger).to receive(:info)
        allow(Rails.logger).to receive(:error)
      end

      it "raises the error" do
        expect { service.call }.to raise_error(Errno::ENOSPC)
      end

      it "logs the error" do
        expect(Rails.logger).to receive(:error).with(/ZIP generation failed/).at_least(:once)
        expect { service.call }.to raise_error(Errno::ENOSPC)
      end
    end
  end
end
