# frozen_string_literal: true

# 実リポジトリの storage/（devの実画像）をテストが変更していないか監視する番兵。
#
# 背景: 2026-07-16、Rails.root を一時ディレクトリに差し替えずに storage/ を
# rm_rf するspec（storage_backup_service_spec 等）が、dev環境の実画像を
# 削除する事故が発生した（S1-5の実.env破壊事故と同じクラスの問題）。
# storage/ の削除・作成・退避を伴うspecは、必ず
# `allow(Rails).to receive(:root).and_return(fake_root)` で隔離すること。
#
# test環境のActive Storageは tmp/storage を使うため（config/storage.yml）、
# 正しく隔離されたテストが実 storage/ に触れることは無い。
RSpec.configure do |config|
  # Rails.rootはspec内でスタブされることがあるため、ロード時に実パスを確定しておく
  real_storage_path = File.expand_path("../../storage", __dir__)
  snapshot = nil

  snapshot_taker = lambda do
    Dir.glob(File.join(real_storage_path, "**", "*"))
       .sort
       .map { |path| [ path, File.file?(path) ? File.size(path) : :dir ] }
  end

  config.before(:suite) do
    snapshot = snapshot_taker.call
  end

  config.after(:suite) do
    current = snapshot_taker.call
    next if current == snapshot

    added = (current - snapshot).map(&:first)
    removed = (snapshot - current).map(&:first)
    raise <<~MSG
      実リポジトリの storage/ がテスト実行によって変更されました！
      storage/ を操作するspecは fake_root（Rails.rootのスタブ）で隔離してください。
      追加/変更: #{added.take(5).inspect}
      削除/変更前: #{removed.take(5).inspect}
    MSG
  end
end
