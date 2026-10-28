# メンテナンスモード運用手順

本番サイト（miyakawa.codes）で、更新作業中に 502 エラーではなく「メンテナンス中」画面を表示するための仕組みです。

## 仕組み

リクエストは `https-portal → nginx → portfolio-web (Rails)` の順に流れます。nginx に次の2つの動作を追加しています（`nginx.production.conf`）。

| 動作 | 条件 | 結果 |
|------|------|------|
| 自動 | Rails コンテナが停止・再作成中で nginx が 502/504 を受け取ったとき | メンテナンス画面を **503** で返す |
| 手動 | フラグファイル `nginx/maintenance/on` が存在するとき | Rails が動いていても全リクエストに **503** を返す |

- 画面本体は `nginx/maintenance/maintenance.html`。60秒ごとに自動再読み込みします。
- `Retry-After: 120` ヘッダーを付けているので、検索エンジンには「一時停止」として扱われ、SEO への影響を抑えられます。
- `/health` はメンテナンス中でも Rails へ素通しします（監視用）。
- フラグファイルは `.gitignore` 済みなので、誤ってコミットされることはありません。

## 手動でメンテナンス画面に切り替える

サーバー上のプロジェクトディレクトリ（`~/web-server/portfolio`）で実行します。nginx の再起動や reload は不要で、即時反映されます。

```bash
# ON
touch nginx/maintenance/on

# OFF
rm nginx/maintenance/on
```

## 使いどころ

- `docker compose up -d` で web / worker コンテナを再作成するとき（自動で切り替わるので操作不要）
- DB メンテナンスなど、Rails は動いているがアクセスを止めたいとき（手動フラグ）

## 注意

- Docker Engine 本体の更新で nginx と https-portal まで停止する場合は、この画面も表示できません。`/etc/docker/daemon.json` に `"live-restore": true` を設定しておくと、Docker デーモンの再起動中もコンテナが動き続けるため、こちらで対処します。
- 設定変更後は `docker compose ... up -d --no-deps nginx` で nginx コンテナを再作成してください。
