require "rails_helper"

# 監査C-10の回帰テスト:
# 管理画面パスの変更（DB履歴の更新）が、プロセス再起動なしで
# 全webプロセスのルーティングに反映されること。
# AdminPathRouteReloaderミドルウェアがリクエスト前にパス変更を検知し、
# 自プロセスのルートを再読み込みする。
RSpec.describe "管理画面パス変更のルート反映", type: :request do
  let(:admin_user) { create(:admin_user) }

  before do
    # テストでは間隔チェックを無効化して毎リクエスト検知させる
    # （他specのリクエストでセットされた間引きタイマーもリセットする）
    stub_const("AdminPathRouteReloader::CHECK_INTERVAL", 0)
    AdminPathRouteReloader.next_check_at = 0.0
  end

  after do
    # 他のspecに影響しないようパス変更を巻き戻す
    AdminPathHistory.delete_all
    Rails.application.reload_routes!
  end

  it "パス変更後、再起動なしで次のリクエストから新パスが有効になる" do
    create(:admin_path_history, admin_user: admin_user, new_path: "new-secret-panel")

    get "/new-secret-panel"

    # 未ログインなのでログイン画面へのリダイレクト（＝ルートが存在する）
    expect(response).to have_http_status(:redirect)
  end

  it "パス変更後、旧パスはルーティングされなくなる" do
    old_path = AdminPath::Resolver.current_path
    create(:admin_path_history, admin_user: admin_user, new_path: "new-secret-panel")

    # test環境はshow_exceptions=:rescuableのためRoutingErrorは404レスポンスになる
    get "/#{old_path}"

    expect(response).to have_http_status(:not_found)
  end

  it "パスに変更がなければルート再読み込みは走らない" do
    allow(Rails.application).to receive(:reload_routes!).and_call_original

    get "/blog"

    # afterフックのクリーンアップ呼び出しより前に検証する
    expect(Rails.application).not_to have_received(:reload_routes!)
  end
end
