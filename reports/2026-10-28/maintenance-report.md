# 本番メンテナンス作業レポート — 2026-10-28

10/25 の脆弱性対応（rubyzip 3.7.0 等）後に残っていた4項目と、追加で依頼されたメンテナンス画面の実装を行った。

## 実施内容

### 1. 旧イメージの削除
- `rollback-20261025` / `rollback-20261025b` の web・worker 計4イメージ（約3GB）と、差し替えで `<none>` になった旧 https-portal イメージを削除。
- 削除前に新イメージが2日間問題なく稼働していることを確認。

### 2. nginx:alpine / https-portal の更新（CVE-2026-111497 brotli）
| イメージ | 結果 |
|---|---|
| steveltn/https-portal:1 | 10/26 ビルドへ更新。libbrotli1 1.1.0-2+deb13u1（修正済み）。証明書は保持（期限 2027-01-11） |
| nginx:alpine | **未更新**。10/22 ビルドでも brotli-libs 1.2.0-r1 のまま（Alpine 3.24 の修正版 1.2.1-r0 が未反映） |

### 3. Docker 本体の更新
- Docker Engine 29.1.2 → 29.9.2、Compose 5.0.0 → 5.6.1、containerd 2.2.0 → 2.4.2。
- 事前に `/etc/docker/daemon.json` に `"live-restore": true` を追加。
- 更新スクリプトはサーバーの `~/upgrade-docker.sh`（sudo が必要なため人間が実行）。

### 4. CI 失敗の通知
原因が3つ重なっていた。
- 毎日実行の Security Audit ワークフローが 2026-06-22 から `disabled_inactivity`（60日間コミットなしで GitHub が自動停止）→ `gh workflow enable` で再有効化。
- 通知ステップに必要な secrets（`RAILS_WEBHOOK_URL` / `INTERNAL_API_TOKEN`）が未登録 → 両方登録。`INTERNAL_API_TOKEN` は本番 `.env.production` にも設定し、`/api/internal/security/bundler_audit` が誤トークンで 401、正しいトークンで 201 を返すことを確認。
- 実際に3か月失敗していたのは ci.yml の `scan_ruby`（CVE-2026-66066、8/3〜10/25）。
- 手動実行で Brakeman / Bundler Audit / Summary すべて success。

### 5. メンテナンスモードの追加（追加依頼）
- `nginx.production.conf`: Rails 停止時（502/504）は自動で 503 のメンテ画面、`nginx/maintenance/on` フラグで手動切替。
- `nginx/maintenance/maintenance.html`: 60秒自動更新、`Retry-After: 120`。
- 手順書: `docs/infrastructure/maintenance_mode.md`。
- 本番で ON/OFF の切り替えを確認済み。

## 作業中のトラブル
- Claude Code からの SSH 試行で公開鍵認証が連続失敗し、Mac のグローバル IP が fail2ban に ban された。Lightsail のブラウザ SSH から `fail2ban-client set sshd unbanip` で解除。原因は鍵のパスフレーズを ssh-agent に登録していなかったこと。今後は接続前に `ssh-add -l` で確認する。

## 残課題
- nginx:alpine の brotli 修正版が公開されたら pull して `up -d --no-deps nginx`。Alpine 3.24 で brotli-libs 1.2.1-r0 が入ったイメージかを `apk list --installed | grep brotli` で確認する。
- Dependabot の auto-merge で CI が失敗したときに気づく仕組みは、Security Audit の通知で代替。必要なら GitHub の Actions 通知設定（Settings → Notifications → Actions）も見直す。
