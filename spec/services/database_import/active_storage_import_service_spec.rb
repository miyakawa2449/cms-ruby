# frozen_string_literal: true

require "rails_helper"

RSpec.describe DatabaseImport::ActiveStorageImportService do
  describe "#call" do
    let(:temp_dir) { Dir.mktmpdir }
    let(:extracted_storage_path) { File.join(temp_dir, "storage") }

    after do
      FileUtils.rm_rf(temp_dir)
      # Clean up any backup directories
      Dir.glob("#{Rails.root.join('storage')}_backup_*").each do |backup|
        FileUtils.rm_rf(backup)
      end
    end

    context "when extracted storage directory exists" do
      before do
        # Create extracted storage with test files
        FileUtils.mkdir_p(File.join(extracted_storage_path, "ab", "cd"))
        File.write(File.join(extracted_storage_path, "ab", "cd", "test_blob.txt"), "test content")
      end

      it "returns true" do
        service = described_class.new(extracted_storage_path)
        expect(service.call).to be true
      end

      it "copies files to Rails storage directory" do
        service = described_class.new(extracted_storage_path)
        service.call

        target_file = Rails.root.join("storage", "ab", "cd", "test_blob.txt")
        expect(File.exist?(target_file)).to be true
        expect(File.read(target_file)).to eq("test content")
      end

      it "logs import progress" do
        service = described_class.new(extracted_storage_path)

        allow(Rails.logger).to receive(:info).and_call_original
        expect(Rails.logger).to receive(:info).with(/Restored \d+ files/).at_least(:once)

        service.call
      end

      context "when existing storage directory has files" do
        let(:existing_file_path) { Rails.root.join("storage", "existing_file.txt") }

        before do
          FileUtils.mkdir_p(Rails.root.join("storage"))
          File.write(existing_file_path, "existing content")
        end

        after do
          FileUtils.rm_rf(Rails.root.join("storage"))
        end

        it "backs up existing storage directory" do
          service = described_class.new(extracted_storage_path)
          service.call

          backup_dirs = Dir.glob("#{Rails.root.join('storage')}_backup_*")
          expect(backup_dirs).not_to be_empty
        end

        it "preserves existing files in backup" do
          service = described_class.new(extracted_storage_path)
          service.call

          backup_dir = Dir.glob("#{Rails.root.join('storage')}_backup_*").first
          backed_up_file = File.join(backup_dir, "existing_file.txt")
          expect(File.exist?(backed_up_file)).to be true
          expect(File.read(backed_up_file)).to eq("existing content")
        end
      end
    end

    context "when extracted storage directory does not exist" do
      it "returns true without error" do
        service = described_class.new(File.join(temp_dir, "nonexistent"))
        expect(service.call).to be true
      end

      it "logs that storage was skipped" do
        service = described_class.new(File.join(temp_dir, "nonexistent"))

        expect(Rails.logger).to receive(:info).with(/No storage directory found/).at_least(:once)
        allow(Rails.logger).to receive(:info).and_call_original

        service.call
      end
    end

    context "when an error occurs during copy" do
      before do
        FileUtils.mkdir_p(extracted_storage_path)
        File.write(File.join(extracted_storage_path, "test.txt"), "test")

        allow(FileUtils).to receive(:cp_r).and_raise(Errno::EACCES, "Permission denied")
        allow(Rails.logger).to receive(:info)
        allow(Rails.logger).to receive(:error)
      end

      it "raises the error" do
        service = described_class.new(extracted_storage_path)
        expect { service.call }.to raise_error(Errno::EACCES)
      end

      it "logs the error" do
        service = described_class.new(extracted_storage_path)
        expect(Rails.logger).to receive(:error).with(/Import failed/).at_least(:once)

        expect { service.call }.to raise_error(Errno::EACCES)
      end
    end
  end
end
