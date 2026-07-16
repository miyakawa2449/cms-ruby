# frozen_string_literal: true

require "rails_helper"

RSpec.describe DatabaseExport::ActiveStorageExportService do
  describe "#call" do
    # 実リポジトリのstorage/を読み書きしないよう一時ディレクトリをRails.rootに差し替える
    # （2026-07-16の実画像削除事故を受けてストレージ系specは全て隔離）
    let(:fake_root) { Pathname.new(Dir.mktmpdir("as_export_spec_root_")) }
    let(:temp_dir) { Dir.mktmpdir }

    before do
      allow(Rails).to receive(:root).and_return(fake_root)
    end

    after do
      FileUtils.rm_rf(temp_dir)
      FileUtils.rm_rf(fake_root)
    end

    subject(:service) { described_class.new(temp_dir) }

    context "when storage directory does not exist" do
      before do
        allow(File).to receive(:directory?).and_call_original
        allow(File).to receive(:directory?).with(Rails.root.join("storage")).and_return(false)
      end

      it "returns true without error" do
        expect(service.call).to be true
      end

      it "logs a warning" do
        expect(Rails.logger).to receive(:warn).with(/Storage directory not found/)
        service.call
      end
    end

    context "when storage directory exists" do
      let(:storage_dir) { Rails.root.join("storage") }

      before do
        FileUtils.mkdir_p(storage_dir)
        # Create test files in storage
        FileUtils.mkdir_p(storage_dir.join("ab", "cd"))
        File.write(storage_dir.join("ab", "cd", "test_file.txt"), "test content")
      end

      it "returns true" do
        expect(service.call).to be true
      end

      it "creates storage directory in temp_dir" do
        service.call
        expect(File.directory?(File.join(temp_dir, "storage"))).to be true
      end

      it "copies files to the target directory" do
        service.call
        target_file = File.join(temp_dir, "storage", "ab", "cd", "test_file.txt")
        expect(File.exist?(target_file)).to be true
        expect(File.read(target_file)).to eq("test content")
      end

      it "logs export summary" do
        allow(Rails.logger).to receive(:info).and_call_original
        expect(Rails.logger).to receive(:info).with(/Copied \d+ files/).at_least(:once)
        service.call
      end
    end

    context "when an error occurs during copy" do
      before do
        allow(File).to receive(:directory?).and_return(true)
        allow(FileUtils).to receive(:mkdir_p)
        allow(FileUtils).to receive(:cp_r).and_raise(Errno::EACCES, "Permission denied")
        allow(Rails.logger).to receive(:info)
        allow(Rails.logger).to receive(:error)
      end

      it "raises the error" do
        expect { service.call }.to raise_error(Errno::EACCES)
      end

      it "logs the error" do
        expect(Rails.logger).to receive(:error).with(/Export failed/).at_least(:once)
        expect { service.call }.to raise_error(Errno::EACCES)
      end
    end
  end
end
