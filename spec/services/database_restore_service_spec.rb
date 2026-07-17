# frozen_string_literal: true

require "rails_helper"

RSpec.describe DatabaseRestoreService do
  let(:tmp_dir) { Dir.mktmpdir("db_restore_spec_") }

  after { FileUtils.rm_rf(tmp_dir) }

  def create_gzipped_dump(content: "fake dump data")
    path = File.join(tmp_dir, "database.dump.gz")
    Zlib::GzipWriter.open(path) { |gz| gz.write(content) }
    path
  end

  it "gzipを解凍しpg_restoreを実行して一時ファイルを削除する" do
    gz_path = create_gzipped_dump
    service = described_class.new(gz_path)

    executed_command = nil
    # 実際のpg_restoreは実行せず、$?を正しく設定するため無害なコマンドを代わりに実行する
    allow(service).to receive(:system) do |_env, *cmd|
      executed_command = cmd
      Kernel.system("true")
    end

    service.execute

    expect(executed_command.first).to eq("pg_restore")
    expect(executed_command).to include("--clean", "--if-exists")
    expect(executed_command.last).to end_with("database.dump")
    # 解凍した一時ファイルは削除されている
    expect(File.exist?(gz_path.sub(/\.gz\z/, ""))).to be false
  end

  it "pg_restore失敗時は例外を投げ、一時ファイルも削除する" do
    gz_path = create_gzipped_dump
    service = described_class.new(gz_path)
    allow(service).to receive(:system) { |_env, *_cmd| Kernel.system("false") }

    expect { service.execute }.to raise_error(/Database restore failed/)
    expect(File.exist?(gz_path.sub(/\.gz\z/, ""))).to be false
  end
end
