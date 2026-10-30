# 指示書: Ruby 3.4.12 更新の後片づけと、CI と同じ条件で RSpec を回すスクリプトの追加

作成日: 2026-10-30
作成: Claude Code(開発機、Mac 側)
対象: 本番サーバー(Lightsail、`~/web-server/portfolio`)で動かす Claude Code
背景の記録: HealthCare リポジトリ `docs/review/ruby-vuln-2026-10.md`(Codex との検討 3 回分)

---

## 0. 経緯(読むだけでよい)

- 2026-10-23 公開の Ruby 3.4.12 で、正規表現エンジン Onigmo(GitLab の CVE-2026-89078 / 93577 / 97229 / 110264)、resolv、zlib、erb の脆弱性修正を取り込んだ。
- このリポジトリは PR #55(Ruby 3.4.7 → 3.4.12)と PR #56(bootsnap 1.19.0 → 1.26.1)を main にマージ済み。本番コンテナは 3.4.12 で稼働中(2026-10-30 に `ruby -v`、`db:migrate:status`、`/up` を確認済み)。
- PR #55 の CI で rspec だけ失敗した。原因は、Ruby 3.4.10 でバックポートされた変更(Coverage 計測中は `RubyVM::InstructionSequence#to_binary` が RuntimeError を出す)と bootsnap 1.19.0 の起動時チェックの組み合わせ。開発機でのローカル検証が `COVERAGE=true` を付けずに RSpec を回していたため見逃した。これが本指示書のタスク B の動機。

---

## 1. 守ること(最優先)

- **本番を止めない。** 稼働中のコンテナ(`portfolio-prod` プロジェクト)に対して `stop` / `down` / `restart` / `rm` をしない。`scripts/deploy.sh` も実行しない。
- **本番サーバーで RSpec を実行しない。** テスト DB の作成や Chrome の導入が要り、2GB メモリの本番機に負荷をかける。テストの実行は開発機か GitHub Actions で行う。本サーバーでやるのはスクリプトの作成と静的な確認まで。
- **削除は提案まで。** 古い Docker イメージや Ruby の削除候補は一覧にして人間に見せ、人間が承認したものだけ消す。承認前に `docker image prune` / `docker system prune` / `rm -rf` を実行しない。
- **main に直接コミットしない。** 作業ブランチを切り、PR を作る。`.env.production` やバックアップファイル(`~/portfolio_before_ruby_3_4_12.sql`)をコミットに含めない。
- 判断に迷ったら作業を止めて選択肢を示す。推測で進めない。

---

## 2. 前提の確認(最初に実行して報告する)

```bash
cd ~/web-server/portfolio
git status --porcelain            # 空であること。空でなければ内容を報告して止まる
git log -1 --format='%h %s'       # main の最新(PR #56 のマージコミット以降)であること
git fetch origin && git status -sb | head -1
docker compose --env-file .env.production -p portfolio-prod -f docker-compose.production.yml ps --format '{{.Name}} {{.Status}}'
docker compose --env-file .env.production -p portfolio-prod -f docker-compose.production.yml exec -T portfolio-web ruby -v   # 3.4.12 であること
```

ここで想定と違う結果が出たら、それ以降のタスクに進まず報告する。

---

## 3. タスク A: 旧 Ruby の後片づけ(調査と提案まで)

### 3.1 注意: rbenv の 3.4.7 / 3.2.2 / 3.2.4 は開発機(Mac)の話

Codex の対策案にあった「rbenv の 3.4.7、3.2.2、3.2.4 を削除するか」は**開発機の rbenv** の話で、`~/development/testRails` が 3.2.2 を参照している。これは開発機側の Claude Code が扱う。本サーバーでは次の 3.2 だけを行う。

### 3.2 本サーバーで調べること

Ruby の更新で不要になったものを一覧にする。**消さない。**

```bash
# サーバー自体に Ruby が入っているか(Docker 以外)
which -a ruby rbenv 2>/dev/null; ruby -v 2>/dev/null; ls ~/.rbenv/versions 2>/dev/null

# Docker イメージの一覧(古いベースイメージと、再ビルド前の portfolio-prod イメージが対象候補)
docker images --format '{{.Repository}}:{{.Tag}}\t{{.ID}}\t{{.Size}}\t{{.CreatedSince}}' | sort
docker images --filter dangling=true --format '{{.ID}}\t{{.Size}}\t{{.CreatedSince}}'

# いま稼働中のコンテナが使っているイメージ ID(これは絶対に削除候補に入れない)
docker compose --env-file .env.production -p portfolio-prod -f docker-compose.production.yml images

# ディスクの状況
df -h / && docker system df
```

### 3.3 報告の形式

次の表を作って人間に渡す。「稼働中が参照」の列が「はい」のものは削除候補から外す。

| 種別 | 名前 / ID | サイズ | 作成 | 稼働中が参照 | 削除候補か | 理由 |
| --- | --- | --- | --- | --- | --- | --- |

削除候補の例: `ruby:3.4.7-slim`(新ビルドは 3.4.12-slim を使う)、再ビルド前の `portfolio-prod-*` イメージ、dangling イメージ。
削除候補にしないもの: `postgres:17-alpine`、`nginx:alpine`、https-portal のイメージ、`ruby:3.4.12-slim`、稼働中コンテナのイメージ。

人間が承認したら、承認された ID だけを `docker rmi <ID>` で 1 つずつ消す。prune 系コマンドは使わない。

### 3.4 バックアップファイル

`~/portfolio_before_ruby_3_4_12.sql`(更新前の pg_dump)は、本番が数日問題なく動いたら人間が削除する。ここでは存在とサイズを報告するだけにする。

---

## 4. タスク B: CI と同じ条件で RSpec を回すスクリプト `bin/rspec-ci` を追加する

### 4.1 目的

`.github/workflows/ci.yml` の rspec ジョブと、開発機のローカル実行で**同じ環境変数と手順**を使えるようにし、「ローカルでは通ったが CI で落ちる」(今回は `COVERAGE=true` の有無)を防ぐ。CI 側もこのスクリプトを呼ぶように変え、条件を 1 か所にまとめる。

### 4.2 現在の CI(`.github/workflows/ci.yml` の rspec ジョブ)がやっていること

スクリプトはこれを忠実に再現する。先に該当箇所を読むこと。

- 環境変数: `RAILS_ENV=test`、`COVERAGE=true`、`SELENIUM=true`、`CHROME_BIN`、`CHROMEDRIVER_PATH`、`XDG_RUNTIME_DIR=/tmp`、`DATABASE_URL=postgres://postgres:postgres@localhost:5432`、`ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY` / `_DETERMINISTIC_KEY` / `_KEY_DERIVATION_SALT`(テスト専用のダミー値。ci.yml に書いてあるものをそのまま使う)
- 手順: `yarn install --frozen-lockfile` → `yarn build:css` → `yarn build` → `bin/rails db:test:prepare && bundle exec rspec --no-fail-fast`

### 4.3 スクリプトの仕様

- 置き場所: `bin/rspec-ci`(実行権限を付ける。既存の `bin/ci` は Rails の ContinuousIntegration 用なので触らない)
- bash、`set -Eeuo pipefail`、冒頭のコメントで「ci.yml の rspec ジョブと同じ条件で実行する。条件を変えるときは両方を同時に直す」と書く
- 環境変数は**未設定のときだけ**既定値を入れる(`${VAR:-default}`)。CI からは ci.yml の値がそのまま使われ、ローカルでは既定値が効く
  - `COVERAGE` の既定値は `true`
  - `DATABASE_URL` の既定値は開発用 `docker-compose.yml` の db サービスに合わせて `postgres://portfolio:portfolio_password@localhost:5432`
  - 暗号化キー 3 つは ci.yml と同じダミー値を既定値にする
  - `SELENIUM` は既定で `true`。`--no-selenium` で付けない(Chrome がない環境向け)
- オプション: `--no-assets`(yarn の 3 ステップを飛ばす。`app/assets/builds` に成果物がある前提)、`--no-selenium`、それ以外の引数はそのまま `rspec` に渡す(例: `bin/rspec-ci spec/models`)
- 終了コードは rspec の結果をそのまま返す
- 最後に `exit code`、`COVERAGE` の値、使った `DATABASE_URL`(パスワード部分は伏せる)を 1 行で表示する

### 4.4 ci.yml の変更

- rspec ジョブの「Build assets」と「Run RSpec with coverage」の 2 ステップを、`run: bin/rspec-ci` の 1 ステップに置き換える
- `env:` ブロック(`CHROME_BIN`、`CHROMEDRIVER_PATH`、`DATABASE_URL`、暗号化キーなど)は**そのまま残す**。スクリプトは未設定時だけ既定値を入れるので、CI の値が優先される
- それ以外のステップ(Postgres サービス、apt、Node、Ruby、Chrome、ChromeDriver ログの出力)は変えない

### 4.5 ドキュメント

- `docs/specifications/features/5.7_test_coverage.md` のローカル実行手順(`COVERAGE=true bundle exec rspec` の箇所)を `bin/rspec-ci` を使う手順に差し替える
- `README.md` にテストの項があれば 1 行足す。なければ足さない

### 4.6 本サーバーでできる確認(ここまで)

```bash
bash -n bin/rspec-ci                      # 構文チェック
command -v shellcheck && shellcheck bin/rspec-ci || echo "shellcheck なし(省略)"
test -x bin/rspec-ci && echo "実行権限 OK"
ruby -ryaml -e 'YAML.load_file(".github/workflows/ci.yml"); puts "ci.yml YAML OK"' 2>/dev/null \
  || docker compose --env-file .env.production -p portfolio-prod -f docker-compose.production.yml exec -T portfolio-web ruby -ryaml -e 'YAML.load_file("/dev/stdin"); puts "ci.yml YAML OK"' < .github/workflows/ci.yml
git diff --check
```

**RSpec 本体はここで実行しない**(1 章)。実際の検証は次の 2 つで行う。

- GitHub Actions: PR を作れば rspec ジョブが `bin/rspec-ci` 経由で走る。これが通ることが完了条件
- 開発機(Mac): 人間または開発機の Claude Code が `docker compose up -d db` のあと `bin/rspec-ci` を実行し、1291 examples(2026-10-30 時点)、0 failures を確認する

### 4.7 ブランチと PR

- ブランチ名: `chore/rspec-ci-script`
- コミットは 2 つに分ける: (1) `bin/rspec-ci` 追加と ci.yml の置き換え、(2) ドキュメント
- PR の本文には、目的(今回の見逃しの再発防止)、CI の条件を 1 か所にまとめたこと、ローカルでの使い方(`bin/rspec-ci`、`bin/rspec-ci --no-selenium --no-assets spec/models`)を書く
- 2026-10-30 時点の `main` には `reports/2026-09-23/` が未追跡で残っていることがある。コミットに含めない

---

## 5. 報告の形式

作業の終わりに次をまとめて人間に渡す。

1. 2 章の前提確認の結果
2. タスク A の表(3.3)と、バックアップファイルの有無・サイズ
3. タスク B で変えたファイルの一覧、4.6 の確認結果、PR の URL
4. 実行しなかったこと(RSpec の実行、削除)と、その理由
5. 人間に判断してもらう点(削除してよいイメージ、PR をマージしてよいか)

---

## 6. 開発機(Mac)側に残っている作業(本サーバーでは扱わない)

参考として書いておく。開発機の Claude Code が担当する。

- rbenv の 3.4.7、3.2.2、3.2.4 を削除するか。`~/development/testRails/.ruby-version` が 3.2.2 を指しているので、testRails を 3.4.12 に上げるか退役させるかを先に決める
- 開発機で `bin/rspec-ci` を実行し、PR の完了条件を満たすこと
