# 管理画面パスの変更を全webプロセスに反映させるミドルウェア（監査C-10対応）。
#
# 背景: ルーティングは起動時に AdminPath::Resolver.current_path を読んで固定される。
# パス変更（管理画面からの手動変更・自動ローテーション）は変更を処理したプロセス
# しか反映されず、他のPumaワーカーや別コンテナ起点の変更では新パスが404になっていた。
#
# 仕組み: リクエスト処理の前に現在のパス（DB履歴 > ENV > デフォルト）と
# ルート構築時のパス（routes.rbが設定する active_path）を照合し、
# 変わっていれば自プロセスのルートを再読み込みする。
# 照合はCHECK_INTERVAL秒に1回に間引く（毎リクエストのDB参照を避ける）。
class AdminPathRouteReloader
  CHECK_INTERVAL = 5 # 秒

  MUTEX = Mutex.new

  class << self
    # routes.rb がルート構築時のパスをここに記録する
    attr_accessor :active_path
    # 次回チェック時刻（monotonic秒）。テストからリセットできるようクラスレベルで保持
    attr_accessor :next_check_at
  end
  self.next_check_at = 0.0

  def initialize(app)
    @app = app
  end

  def call(env)
    reload_routes_if_path_changed
    @app.call(env)
  end

  private

  def reload_routes_if_path_changed
    now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    return if now < self.class.next_check_at

    MUTEX.synchronize do
      now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      return if now < self.class.next_check_at

      self.class.next_check_at = now + self.class::CHECK_INTERVAL

      current = AdminPath::Resolver.current_path

      # ルートがまだ構築されていない（active_path未設定の）初回は記録のみ。
      # 実際のルート構築時にroutes.rbが同じ値を設定する
      if self.class.active_path.nil?
        self.class.active_path = current
        return
      end

      return if current == self.class.active_path

      Rails.application.reload_routes!
      self.class.active_path = current
      Rails.logger.info("[AdminPath] 管理画面パスの変更を検知し、ルートを再読み込みしました")
    end
  rescue StandardError => e
    # チェックに失敗してもリクエスト処理は継続する（従来どおり再起動で反映される）
    Rails.logger.warn("[AdminPath] ルート再読み込みチェックに失敗: #{e.class}: #{e.message}")
  end
end
