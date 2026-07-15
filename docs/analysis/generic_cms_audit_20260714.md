# 汎用CMS化に向けた仕様・実装不整合の監査レポート

- **調査日**: 2026-07-14
- **調査者**: Claude Code（6並列調査エージェントによるリポジトリ全体監査）
- **調査方法**: 静的解析のみ（開発用DBコンテナ停止中のため実行時検証は未実施）
- **凡例**: 【事実】= コードを直接読んで確認した内容 ／ 【推測】= コードから導いた動作予測（500エラー化など）
- **ステータス**: 2026-07-15 仕様確認への回答を受領し、方針を「現行モデル完成 → 汎用化」の二段階に改訂（末尾の改訂セクション参照）。コード変更は未着手。

---

## 総評

ENV/SiteSettingによる設定機構は「骨格」として存在するが、以下の状態にある。

1. ビュー層とフォールバック値の大半が開発者個人（実名・SNS・経歴・所在地・ドメイン）にロックインされている
2. 新規環境では起動・主要機能が壊れる箇所が複数ある
3. 管理画面の設定が実際には部分的にしか効かない
4. 機能停止級のバグが管理画面に3件ある（タグ編集・Contact FK・Serviceセクション）

テストカバレッジ自体は良好（CI実測 88.86%）だが、CIはmainで約3ヶ月失敗したまま放置されている。

---

## 🔴 Critical（12件）

### C-1. 第三者環境では本番起動できない（credentials前提）

- **対象**: `config/credentials.yml.enc`（コミット済）、`.gitignore:35`（master.key除外）、`docker-compose.production.yml`
- **現在の実装**【事実】: 本番の `secret_key_base` は開発者のmaster.keyでしか復号できないcredentialsに依存。`SECRET_KEY_BASE` の代替設定なし。
- **本来の仕様**: 第三者がcredentialsを再生成して起動できるセットアップ手順が存在すること。
- **問題**: master.keyを持たない第三者は本番起動時に `Missing secret_key_base` で即死【Rails仕様に基づく高確度の推測】。master.keyを同梱すれば今度は開発者の秘密が漏れる。
- **修正方針**: 配布時credentials再生成を前提とした手順書化 + 必要キーの一覧化（ENVフォールバック追加も検討）。
- **影響範囲**: デプロイ手順・ドキュメントのみ（アプリコードほぼ変更なし）。
- **必要なテスト**: クリーン環境での起動スモークテスト（CI上で credentials 再生成→boot 確認）。

### C-2. 新規環境ではお問い合わせフォーム送信が500になる（暗号鍵未設定）

- **対象**: `app/models/contact.rb:5-7`（`encrypts :email/:name/:message`）、`config/environments/test.rb:41-52`、`config/initializers/active_record_encryption.rb`
- **現在の実装**【事実】: Active Record Encryptionの鍵設定が**test環境にしか存在しない**。dev/prodはcredentials内の鍵に依存（開発者環境にのみ存在すると推定）。
- **本来の仕様**: 新規環境でも暗号鍵をセットアップでき、お問い合わせが保存できること。
- **問題**: credentialsを再生成しただけの新規環境では `Contact#save` で暗号化設定エラー → POST /contacts が500【高確度の推測】。`db:encryption:init` の手順はどこにも記載なし。
- **修正方針**: 鍵設定をENVフォールバック付きで全環境に定義し、セットアップ手順に `db:encryption:init` を明記。
- **影響範囲**: initializer 1ファイル + ドキュメント。既存データの復号互換に注意。
- **必要なテスト**: 鍵未設定時に明確なエラーメッセージで落ちることの検証、Contact保存のrequest spec（鍵設定経路の追加）。

### C-3. Serviceセクションを有効化するとトップページ全体が500

- **対象**: `db/seeds.rb:61`（`name: 'service'`）、`app/views/portfolio/index.html.erb:85`（`render "portfolio/sections/#{section.name}"`）、実在パーシャルは `_services.html.erb`（複数形）のみ
- **現在の実装**【事実】: セクション名 `service` に対応するパーシャル `_service.html.erb` が存在しない。`scripts/init_sections.rb` では `"services"` と、命名が三重に不整合。
- **本来の仕様**: seedされる全セクション名に対応パーシャルが存在すること。
- **問題**: seed直後はコンテンツ未登録でスキップされるため潜伏するが、管理画面からServiceセクションのコンテンツを作成・有効化した瞬間に `MissingTemplate` でトップページ全体が500【高確度の推測】。
- **修正方針**: セクション名かパーシャル名のどちらかに統一（既存データがある環境向けにdata migrationも必要）。
- **影響範囲**: seeds、パーシャル名、既存DBのsectionsレコード。
- **必要なテスト**: 全seedセクション名に対応パーシャルが存在することを機械的に検証するspec + Serviceセクション有効化時のsystem spec。

### C-4. タグの新規作成・編集画面が開けない（存在しないカラムを参照）

- **対象**: `app/views/admin/tags/_form.html.erb:35-54`（`description`/`color`/`icon`）、`db/schema.rb:497-505`（tagsは `name/slug/article_count` のみ）
- **現在の実装**【事実】: categoriesフォームのコピペと思われる3フィールドが残存し、`tag.color` を直接呼ぶ行もある。permitは `:name, :slug` のみ。
- **本来の仕様**: フォームはモデルの実属性のみ参照すること。
- **問題**: `/admin/tags/new`・`edit` 表示時に `NoMethodError` で500 → **タグのUI経由での作成・編集が現状不可能**【高確度の推測。カラム不存在とrender経路は事実】。
- **修正方針**: フォームから3フィールドを削除（またはtagsにカラム追加＝仕様判断 → 確認事項10）。
- **影響範囲**: ビュー1ファイル。
- **必要なテスト**: `admin/tags` の new/edit request spec（現状欠落しているからこそ見逃されていた）。

### C-5. Contactの担当者アサイン機能が構造的に動作しない（FK名不一致）

- **対象**: `app/models/contact.rb:2`（`foreign_key: :assigned_to`）、実カラムは `assigned_to_id`（`db/schema.rb:197`）、`app/controllers/admin/contacts_controller.rb:5`（`includes(:admin_user)`）、`:54`（`permit(:assigned_to)`）
- **現在の実装**【事実】: アソシエーションが存在しないカラム名を指す。permitも同名。テストでの検証ゼロ。
- **本来の仕様**: `foreign_key: :assigned_to_id`（またはアソシエーション名を `assigned_to` に変更）。
- **問題**: 問い合わせ一覧の `includes(:admin_user)` がpreload時に例外化する見込み（＝レコードがあると一覧が500）、update時は `UnknownAttributeError`【例外化は高確度の推測】。
- **修正方針**: `foreign_key: :assigned_to_id` へ修正、permitとUIの整合（アサインUI自体が未実装 → M-17と合わせて対応）。
- **影響範囲**: モデル1行 + コントローラ。
- **必要なテスト**: 問い合わせ存在時の一覧表示spec、アサイン更新のrequest spec。

### C-6. 認証なしデバッグエンドポイント `/test` が本番公開

- **対象**: `config/routes.rb:9`、`app/controllers/simple_test_controller.rb`、`app/models/test_item.rb`、`db/migrate/20251213033842`、`db/seeds/create_test_data.rb`、`spec/requests/simple_test_spec.rb`
- **現在の実装**【事実】: 環境ガード・認証なしで、DB接続状態・レコード内容・例外バックトレースを誰にでも表示。
- **本来の仕様**: デバッグ用コードは本番ルーティングに存在しないこと。
- **問題**: 情報漏洩ベクタ。配布物として論外。
- **修正方針**: ルート・コントローラ・モデル・テーブル・seed・specの一式削除（参照が閉じた集合であることはgrep確認済み【事実】）。
- **影響範囲**: 削除のみ。`test_items` テーブルのdrop migrationが必要。
- **必要なテスト**: `/test` が404になることのspec（削除確認）。

### C-7. 秘匿すべき管理画面パスがrobots.txtとコードで公開されている

- **対象**: `public/robots.txt:11-12`（`Disallow: /admin-secure-panel-miyakawa2449`）、`app/services/admin_path/resolver.rb:3`（`DEFAULT_PATH` に同値）、`nginx.production.conf:12`、`scripts/deploy.sh:497`
- **現在の実装**【事実】: 「URL秘匿」目的の機能なのに、その値が誰でも読める静的ファイルとリポジトリに平文で存在。robots.txtは管理画面から変更不可。
- **本来の仕様**: 管理画面パスは環境ごとの秘密値であり、リポジトリ・公開ファイルに含まれないこと。
- **問題**: セキュリティ機能の自己否定 + 全配布先が同じ「隠しパス」になる。
- **修正方針**: robots.txtから当該行を削除（Disallowで隠すこと自体が逆効果）、`DEFAULT_PATH` は無害な値（例: `admin`）に変更 or 未設定時はセットアップで必須入力に。
- **影響範囲**: 既存環境の管理URL変更を伴うため移行手順が必要。
- **必要なテスト**: Resolver単体spec（現状未テスト。ENV/DB/デフォルトの優先順位検証）。

### C-8. 開発者の実名・SNS・経歴・所在地が公開ページ全域に直書き（約30箇所超）

- **対象**（代表箇所）【事実】:
  - `app/views/shared/_footer.html.erb:20,39-49,64` — 「Miyakawa Codes」、X/Facebook/GitHubの個人アカウント、© 2024
  - `app/views/shared/_header.html.erb:22,24` — 「Miyakawa Codes Blog」「Miyakawa Codes」
  - `app/views/portfolio/index.html.erb:14,95-134` — 同一のサイト名・SNS・コピーライトがもう1セット重複直書き
  - `app/views/layouts/application.html.erb:7,14` — `<title>` フォールバック「宮川 剛 - シニアエンジニアのポートフォリオ」、application-name「宮川 剛 Portfolio」
  - `app/services/meta_tags_service.rb:62-227` — OGP/Twitter Cardの実名・`@miyakawa2449`（TODOコメント付き）・個人史説明文。blog/category/my_story系はSiteSettingでの上書き手段なし
  - `app/views/portfolio/sections/_contact.html.erb:113-128` — 「石川県金沢市」「営業時間: 月曜〜木曜 10:00-16:00」を**条件分岐なしで**表示
  - `app/views/portfolio/sections/_my-story.html.erb:93-116` — 個人史ブロックが分岐なし直書き（管理画面から変更不可）
  - `app/views/portfolio/sections/_hero.html.erb:30-43`、`_about.html.erb:16-139` — フォールバックが個人経歴
  - `app/mailers/contact_mailer.rb:18` + メールテンプレート4種 — 件名・本文に「Miyakawa Codes」
  - `app/views/blog/show.html.erb:267-292` — 著者ボックスが「宮川 剛」固定（記事著者と無関係）
  - `app/views/my_story/index.html.erb:48-201`、`app/controllers/my_story_controller.rb:35` — フォールバックが個人年表
  - `app/helpers/structured_data_helper.rb:152,235` — `ENV.fetch("SITE_NAME", "宮川 剛 - Portfolio")`
  - `public/404.html:7` / `public/500.html:7` — 静的エラーページに「Miyakawa Codes」
  - `db/seeds/my_story_data.rb` ほかseed群 — 実名入り個人データ・個人GitHub URL
- **本来の仕様**: サイト名・著者・SNS・連絡先情報はすべてSiteSetting（DB）またはENVで管理され、フォールバックは無害な汎用値であること。
- **問題**: DB未投入・設定未変更の第三者環境で、公開ページ・SNSシェア・送信メールの随所に開発者情報が表示される。
- **修正方針**: SiteSettingのキー拡張（著者名、SNSリンク、コピーライト、twitter_site、連絡先情報等）+ ビューの参照置換 + フォールバックの汎用値統一。
- **影響範囲**: ビュー約30ファイル、meta_tags_service、mailer。表示崩れリスクがあるため段階的に。
- **必要なテスト**: 主要ページのビューspec（設定値反映／個人固有文字列が出力に含まれないことのregressionチェック）。

### C-9. SiteSettingのメモ化により、設定変更が他プロセスに「無期限」で反映されない

- **対象**: `app/services/site_setting_cache_manager.rb:5-16`（`@memoized_settings ||=`）、`config/puma.rb:32`（本番2ワーカー）+ Solid Queue別コンテナ
- **現在の実装**【事実】: クラス変数メモ化に有効期限がなく、`clear_cache` は実行プロセスのみクリア。共有キャッシュ（solid_cache）はメモ化に短絡され使われない。スレッドセーフでもない。
- **本来の仕様**: 設定保存後、全プロセスで次リクエストから新値が反映されること。
- **問題**: 管理画面で設定（ロゴ・favicon・サイトタイトル・GTM等全6キー）を保存しても、他のPumaワーカーはプロセス再起動まで旧値を返す。「反映されたりされなかったり」のワーカーガチャ【マルチプロセス下の挙動は構成から導いた高確度の推測】。
- **修正方針**: メモ化を廃止し `Rails.cache`（共有ストア）のみに依存、またはリクエスト単位のメモ化（`ActiveSupport::CurrentAttributes`）へ。
- **影響範囲**: キャッシュマネージャ1ファイル。パフォーマンス影響は軽微（solid_cacheヒット）。
- **必要なテスト**: 「保存→別インスタンス相当の読み出しで新値」のspec、キャッシュクリア経路のspec。

### C-10. 管理画面URL変更が全プロセスに反映されない（変更後404）

- **対象**: `app/services/admin_path/updater.rb:45-63`（`ENV書換` + `reload_routes!`）、`config/routes.rb:2`（起動時固定）、`app/jobs/admin_path/rotation_job.rb`
- **現在の実装**【事実】: ルートは起動時に固定され、変更処理は実行プロセス内のみreload。自動ローテーションは別コンテナのジョブプロセスで走る。
- **本来の仕様**: パス変更が全webプロセスのルーティングに反映されること。
- **問題**: 手動変更では変更を処理しなかったワーカーで新URLが404（確率的に発生）。自動ローテーションでは**通知メールに書かれた新URLが全webプロセスで404のまま**【構成から導いた高確度の推測】。再起動後は正常化する（ResolverがDB優先のため【事実】）。既存セッションの強制ログアウトはDB参照のため全プロセスで機能【事実】。
- **修正方針**: パスを固定ルート化しconstraint/ミドルウェアでDB値と照合する方式へ設計変更。少なくとも自動ローテーション機能は修正までデフォルト無効を維持。
- **影響範囲**: ルーティング設計の変更（中規模）。
- **必要なテスト**: `AdminPathSettingsController` のrequest spec（現状ゼロ【事実】）、パス変更後の新旧URL挙動のintegration spec。

### C-11. デフォルトOGP画像が「画像ではないテキストファイル」

- **対象**: `public/og-default.jpg`（114バイトのASCIIテキスト。中身はプレースホルダーメモ）、配信元 `app/services/site_assets_service.rb:121-126`
- **現在の実装**【事実】: og_image未設定時にこの壊れたファイルのURLが og:image として配信される。
- **本来の仕様**: 有効なデフォルトOGP画像が同梱されていること。
- **問題**: 初期状態でSNSシェアのOGP画像が必ず壊れる。
- **修正方針**: 実画像（無地の汎用デフォルト）に差し替え。
- **影響範囲**: 静的ファイル1つ。
- **必要なテスト**: ファイルが有効な画像であることの検証（軽量なspecで可）。

### C-12. 本番インフラ設定が開発者ドメインに固定

- **対象**: `nginx.production.conf:3,17-47`（`miyakawa.codes` 7箇所）、`docker-compose.production.yml:89`、`scripts/deploy.sh:386,496-497`（+ `.bak` にも）
- **現在の実装**【事実】: ドメインが変数化されておらず、deploy.shは秘密の管理パス入りURLをechoする。
- **本来の仕様**: ドメインは環境変数/テンプレートで注入できること。
- **問題**: 配布先はそのままでは動かず、複数ファイルの手作業書き換えが必要。
- **修正方針**: 環境変数/テンプレート化（`${DOMAIN}` 方式）、`.bak` は削除。
- **影響範囲**: インフラ設定ファイルのみ（アプリコード無関係）。
- **必要なテスト**: なし（デプロイ手順書での確認事項）。

---

## 🟠 High（16件）

### H-1. MyStorySectionのカスタムバリデーションが論理反転で完全無効

- **対象**: `app/models/my_story_section.rb:224-230`、`app/services/my_story_section_validator.rb:7-15`
- **現在の実装**【事実】: `return unless validator.validate_all` — validate_allは「妥当ならtrue」を返すため、**不正なときに早期returnし、妥当なときだけ空のerrorsを走査**。229行のバリデータ全体がno-op。付随して `check_depth`（validator:198-200）内のraiseも到達不能。
- **本来の仕様**: `return if validator.validate_all`（妥当なら何もしない）。
- **問題**: セクション種別固有の必須チェック・JSON検証・position制約がすべて素通りし、不完全なデータが保存される。
- **修正方針**: 1行修正。**ただし修正すると休眠していた検証が起き、既存データ・既存フローが弾かれる可能性がある**ため、既存レコードの妥当性確認とセットで（ロードマップではフェーズ5に配置）。
- **影響範囲**: My Story管理画面の保存可否が変わる。
- **必要なテスト**: 不正データが実際に弾かれることのモデルspec（現状はno-opを前提に通っている可能性）。

### H-2. 「予約投稿」がUIに存在するが、機能として成立していない

- **対象**: `app/views/admin/articles/_form.html.erb:384-387`（選択肢あり・`published_at` 入力欄なし【事実】）、`app/services/article_publishing_manager.rb:88-100`（`publish_scheduled_articles!` の呼び出し元はspecのみ【grepで事実】）、ジョブ登録なし（`recurring.yml`/`queue.yml` とも【事実】）、`app/models/article.rb:136-140`（published時のみpublished_at自動設定）
- **問題**: scheduledで保存すると `published_at` がnilのまま宙に浮き、公開一覧に出ず自動公開もされない【高確度の推測】。
- **修正方針**: 【仕様確認が必要 → 確認事項1】(a) 日時入力欄+定期ジョブを実装して完成させる、(b) UIから選択肢を削除する、の二択。
- **影響範囲**: (a)ならフォーム+ジョブ+recurring登録、(b)ならフォームのみ。
- **必要なテスト**: (a)の場合は予約→自動公開のジョブspec+時刻境界値、(b)の場合はstatus選択肢のspec。

### H-3. 定期ジョブのスケジュール定義が3ファイルに重複し、時刻も食い違う。管理パス自動ローテーションは未実行の疑い

- **対象**: `config/recurring.yml`（daily 2:00 等）、`config/queue.yml`（`0 3 * * *` 等 + `admin_path_rotation`）、`config/initializers/sidekiq_cron.rb`（3箇所目）
- **事実**: 3ファイルに同種の定義があり時刻不一致（daily 2:00 vs 3:00、monthly 3:00 vs 4:00）。`admin_path_rotation` は queue.yml にしか存在しない。
- **推測（要検証）**: Solid Queue 1.2.4 では `recurring.yml` が正で、queue.ymlの `recurring_tasks` は読まれない可能性が高い。その場合ローテーションジョブは一度も実行されていない。
- **修正方針**: `recurring.yml` へ一本化し、Solid Queueの実挙動を検証してから rotation の登録可否を決定。
- **影響範囲**: 設定ファイルのみ。
- **必要なテスト**: recurring設定の読み込み検証（起動時にスケジュール一覧をassertするspec or 手動検証手順）。

### H-4. seedsのMy Storyデータが実際には投入されない + 投入経路は破壊的

- **対象**: `db/seeds.rb:78`（`load`）、`db/seeds/my_story_data.rb:200`（`if __FILE__ == $0` ガードでload経由では実行されない【Ruby仕様に基づく高確度推測。構造は事実】）、同`:6`（`MyStorySection.destroy_all`）
- **問題**: seed後もMyStorySectionは0件で、`/my-story` はフォールバック（＝開発者の個人史）表示。ガードを外すと今度は再seedのたびに管理画面で編集したデータが全削除される。さらに投入内容自体が実名入り個人データ。
- **修正方針**: `find_or_create_by` ベースの冪等なseedに書き換え + 内容をサンプルデータ化。
- **影響範囲**: seedファイルのみ。
- **必要なテスト**: seed 2回実行で冪等であることのspec。

### H-5. 本番でADMIN_PASSWORD未設定だと管理者が作られず、エラーも出ない

- **対象**: `db/seeds.rb:11-13`、`bin/docker-entrypoint-production:9-12`
- **事実**: 起動は成功するが管理画面に永久にログインできず、entrypointが毎起動seedを再実行し続ける。
- **修正方針**: 未設定時は起動を明示的に失敗させる（fail-fast）か、初回セットアップウィザードを設ける。
- **必要なテスト**: ENV未設定時のseed挙動spec。

### H-6. 配布物にREADME・本番用envテンプレートが含まれない

- **対象**: `.gitignore:52-53`（`README.md`/`CLAUDE.md` をignore【事実】）、`.gitignore:11`（`/.env*` により `.env.production.example` が未追跡。追跡済みは `.env.example` のみ【git ls-filesで事実】）。一方 `docker-compose.production.yml` は `.env.production` の物理的存在を必須とする。
- **問題**: 第三者はセットアップ手順も本番envテンプレートも入手できない。
- **修正方針**: `.gitignore` に `!.env.production.example` を追加、READMEのignore解除、必須ENV一覧を記載。
- **必要なテスト**: なし（配布物チェックリストで担保）。

### H-7. `site_title`/`site_description` 設定が一部ページにしか効かない

- **対象**:
  - 効く【事実】: `portfolio/index.html.erb:1-2`、`meta_tags_service.rb:62-65,200-201`、`feeds_controller.rb:29-30`
  - 効かない【事実】: `layouts/application.html.erb:7`（タブタイトル）、`blog/index.html.erb:1`・`blog/show.html.erb:1`、`meta_tags_service.rb:86,110,135,213-225`（og:site_name は常にハードコード）、ヘッダー/フッターのサイト名テキスト全部
  - 反映用ヘルパー `NavigationHelper#page_title`（`navigation_helper.rb:28-36`）は**未使用のデッドコード**【grepで事実】
- **問題**: 管理画面のUI説明（「ブラウザのタブやSNSシェア時に表示される」`admin/site_settings/index.html.erb:104`）と実挙動が乖離。
- **修正方針**: `page_title` ヘルパーを軸にタイトル生成を一元化し、og:site_name・ヘッダー/フッターも設定参照へ。C-8と同時対応が効率的。
- **必要なテスト**: 設定値変更が全ページ種別の `<title>`/OGPに反映されるview/request spec。

### H-8. `article_count` の意味がコールバック間で食い違い、タグ解除時は更新漏れ

- **対象**: `article.rb:147-153`（公開記事のみ）vs `article_category.rb:10-12`・`category.rb:43-45`（全記事）。`article_tag.rb` はコールバックなし + Article側は現在関連中のタグのみ巡回【事実】。利用側: `tag.rb:10` `scope :popular`。
- **問題**: 同一カラムが操作順で公開数/全件数を行き来し、外したタグのカウントが残って `popular` スコープに記事ゼロのタグが出続ける【シナリオは高確度推測】。
- **修正方針**: 【仕様確認が必要 → 確認事項2】「公開記事数」か「全記事数」かを確定 → 単一のカウンタ更新サービスに集約 + 再計算rakeタスク。
- **必要なテスト**: 公開↔下書き遷移・タグ付け外しの境界ケースを含むカウンタspec（TDD必須領域）。

### H-9. `attr_accessor` が実在するDBカラム3本を隠蔽（skills/achievements/quote）

- **対象**: `app/models/my_story_section.rb:53` vs `db/schema.rb:236,242,244`。実データは `additional_data` jsonb に保存（`my_story_section.rb:203-222`）【事実】。モデル冒頭のスキーマ注記も陳腐化。
- **問題**: DBカラムは永久にNULLのデッドカラム。かつ `sync_chapter_fields_to_additional_data` は `present?` 時のみ書き込むため**フォームで値を空にしてもクリアできない**【事実】。
- **修正方針**: 【仕様確認が必要 → 確認事項3】カラムを使うのかjsonbに寄せるのか確定し、使わない側を削除。クリア操作を可能に。
- **必要なテスト**: 空更新でクリアされることのspec。

### H-10. LICENSEファイル不在 + 未使用のLGPL gem

- **対象**: リポジトリにLICENSE/COPYINGなし【git ls-filesで事実】。`sidekiq 8.1.0（LGPL-3.0）` は実運用がSolid Queueのため事実上未使用（本番composeにRedis/Sidekiqサービスなし）【事実】。prawnはトリプルライセンス（Rubyライセンス選択で配布可能【一般知識に基づく推測】）。
- **問題**: ライセンス未定義のまま販売・配布は法的に不明瞭。
- **修正方針**: 販売形態を決めてLICENSE策定（→ 確認事項8）。Sidekiq系gem（sidekiq/sidekiq-cron/sentry-sidekiq/redis）は削除で懸念ごと解消。
- **必要なテスト**: gem削除後の全spec通過 + 定期ジョブ動作確認。

### H-11. i18nが実質機能していない（日本語専用）

- **対象**: `config/application.rb:27-28` は `[:ja, :en]` 宣言だが、`en.yml` 31行 vs `ja.yml` 192行。日本語ハードコード: view 120ファイル・controller 29・service 34【grepで事実】。`t()` 使用は5ビューのみ。
- **修正方針**: 【仕様確認が必要 → 確認事項5】「日本語専用CMS」として売るなら現状維持+宣言の整理。多言語対応するなら全ビューの `t()` 化（大工事）。
- **必要なテスト**: 多言語化する場合はロケール切替のsystem spec。

### H-12. 認可レイヤー不在・シングルユーザー前提

- **対象**: Punditが `Gemfile` にあるが使用ゼロ（`app/policies/` 不在、`authorize`/`policy_scope` 使用0件）【事実】。`:registerable` 無効化コメントで単一ユーザー前提を明言（`admin_user.rb:2-4`、`routes.rb:13-17`）、`AdminUser.first` 固定（`rotation_job.rb:9`）、roleカラムなし、`has_many :articles, dependent: :destroy`（管理者削除で記事全消し）【事実】。
- **修正方針**: 【仕様確認が必要 → 確認事項4】複数管理者+ロールを要件に入れるか。入れないなら未使用のPunditは削除し「単一管理者製品」と明記。`dependent: :destroy` は `nullify` への変更を検討。
- **必要なテスト**: 要件確定後に認可のrequest spec一式。

### H-13. MyStorySectionのタイプ定数に開発者個人のキャリアが焼き込み

- **対象**: `app/models/my_story_section.rb:30-50` — `SECTION_TYPES`/`SECTION_TYPE_LABELS` に「第1章: パソコンスクール講師時代」「第3章: AI活用エンジニア時代」等を定数化。inclusionバリデーション+UNIQUE制約で拡張不可【事実】。
- **問題**: My Story機能が「作者の自伝専用モジュール」になっており、汎用CMSの機能として成立しない。
- **修正方針**: 【仕様確認が必要 → 確認事項3】タイプ/ラベルのDB定義化、または機能自体をオプションモジュール化。
- **必要なテスト**: 設計確定後。

### H-14. CIがmainで約3ヶ月失敗したまま（テスト1件 + 既知脆弱性2件）

- **対象**【CIログで事実】: rspec 1264例中1失敗（`spec/helpers/markdown_helper_spec.rb:35`、OGPカード置換）、bundler-auditが `action_text-trix 2.1.16` のXSS 2件（GHSA-53p3-c7vp-4mcc ほか、要 ≥2.1.18）を検出。加えてminitestジョブは0件のまま空回り（テスト実態はRSpec 139ファイル、`test/` は空）【事実】。カバレッジはCI実測 88.86%（2026-04-22）。
- **修正方針**: 最優先でグリーン化（spec修正 + trix更新）。minitestジョブはCI定義から削除。
- **影響範囲**: 以降の全修正の安全網になるため、**ロードマップの起点**。
- **必要なテスト**: CI自体の再グリーン化。

### H-15. S3バックアップのデフォルトバケットが開発者名義

- **対象**: `app/services/s3_service.rb:12` — `ENV.fetch("S3_BACKUP_BUCKET", "portfolio-backup-miyakawa-codes")`【事実】。`spec/services/s3_service_spec.rb:4` も同名を期待。
- **問題**: ENV未設定の第三者環境でバックアップジョブが開発者のバケット名へアクセスを試行。
- **修正方針**: デフォルト削除しfail-fast（未設定なら明示エラー）に。
- **必要なテスト**: ENV未設定時のエラーメッセージ検証spec。

### H-16. admin_path機能のコントローラ層・Resolverが未テスト

- **対象**: `Admin::AdminPathSettingsController` のrequest specなし、`AdminPath::Resolver`（routes起動時のDBフォールバック）の単体specなし【事実】。壊れると管理画面に入れなくなる機能なのに未検証。
- **修正方針**: C-7/C-10の修正時に必ずspecを追加。
- **必要なテスト**: Resolverの優先順位（DB > ENV > デフォルト）、パス変更フローのrequest spec。

---

## 🟡 Medium（主要19件・要約）

### 設定・反映系

1. **GTM IDを空に戻せない** — `site_settings_controller.rb:72` は `has_key?` で空更新を意図するが、text型バリデーション（`site_setting_type_manager.rb:74-77`）がblank一律拒否。UI説明「空欄の場合はGTMタグは出力されません」（`admin/site_settings/index.html.erb:131`）と矛盾【事実】。→ blank許可の型別制御。
2. **DBインポート後に設定キャッシュ未クリア** — `database_import_service.rb:117-129` は `insert` でコールバック不発火【事実】。リストア後に旧サイトタイトル・旧ロゴが表示され続ける。→ インポート完了時に明示クリア。
3. **2FAの「デバイス信頼(30日)」が到達不能** — サインイン直後に `session[:two_factor_authenticated]=true` を無条件セット（`admin_users/sessions_controller.rb:7-11`）するためverify画面（`two_factor_auth_controller.rb:98-122`）に到達せず、`handle_device_trust`（:135-146）は呼ばれない【事実+一部推測】。2FA必須化自体は機能【事実】。→ デッドフローの削除かDevise戦略との統合。
4. **フォールバックのサイト名が4種バラバラ** — 「Miyakawa Codes - ポートフォリオ」（type_manager）／「宮川 剛 - シニアエンジニアのポートフォリオ」（meta_tags）／「Miyakawa Codes」（navigation_helper）／「Tech Blog」（feeds）【事実】。→ C-8対応時に統一。

### 新規環境・運用系

5. **rack_attackのフォールバックが機能しないロジックバグ** — `config/initializers/rack_attack.rb:6-19`。MemoryStore設定直後に無条件でredis_cache_storeで上書き。Redis無し本番で**レート制限が静かに全無効化**【上書きは事実、素通りは推測】。
6. **SES未設定の本番でメール通知ジョブが失敗し続ける** — `production.rb:100-105`（delivery_method=:smtpでsmtp_settings無し）、`aws_ses.rb:10-17`（未設定時は警告ログのみ）【設定不在は事実】。問い合わせ自体は保存されるが通知・自動返信が届かず、気づく手段がログ以外に無い。
7. **AWS未設定でもバックアップジョブがデフォルト有効** — `config/recurring.yml` に登録済み + `s3_service.rb:9-10` の `ENV.fetch`（デフォルト無し）でKeyError。毎日失敗蓄積。無効化フラグなし【事実】。
8. **database.ymlの明示キーがDATABASE_URLより優先され host: db 固定** — `config/database.yml:14-19`。Docker Compose以外で接続不能【ハードコードは事実、優先順位はRails仕様に基づく推測】。
9. **workerコンテナが db:prepare を通らず初回起動レース** — `bin/docker-entrypoint-production:4-7` + `docker-compose.production.yml:62`【構成は事実、レースは推測。restartで自然回復見込み】。
10. **pg_dump のPATH/バージョン依存** — `database_backup_service.rb:27-40` が `system()` 直呼び【事実】。配布先で壊れやすい。

### データ整合性系

11. **SEO/OGカラムにlengthバリデーション無し** — `db/schema.rb:143-146`（varchar 500/255）に対し `article.rb` は未検証、フォームにmaxlengthも無し。超過で `ValueTooLong` の500【非対称は事実】。`categories.icon`（varchar 50）も同様。
12. **og_title/og_descriptionのdelegateがフォールバック値を編集フォームに表示→保存で実カラムに焼き込み** — `article.rb:115-118` + `article_meta_manager.rb:81-87`。「未設定＝タイトル追従」状態が失われる【焼き込みは高確度推測】。付随: `article_meta_manager.rb:48` の `read_attribute(:meta_title)` は**存在しないカラム**参照のデッドコード【事実】。
13. **booleanカラム4本がNOT NULL無しで三値化リスク** — `sections.is_visible` / `section_contents.is_active` / `contacts.is_spam` / `vulnerabilities.fixed`（defaultはあり）【欠落は事実】。`update_all`・インポート経由でnil混入するとスコープから漏れる。
14. **slug/nameのcase_insensitiveバリデーション vs case_sensitiveなDB unique index** — `article.rb:36`・`tag.rb:7-8` vs `db/schema.rb:158,503-504`。レースで大小文字違い重複が入り、`find_by!(slug:)` で片方に到達不能【不一致は事実】。
15. **AIコスト精度不一致** — `ai_generations.cost` decimal(10,6) vs `ai_usage_stats.total_cost` decimal(10,2)。日次集計で少額コストが丸め消失【スキーマは事実】。
16. **categoriesのmove_up/downがスワップせずposition重複を生む** — `admin/categories_controller.rb:54-62` が `Positionable#move_up` を使わず素朴に `position - 1` 更新【事実】。
17. **contacts editテンプレート不在** — `admin/contacts_controller.rb:2,15-16,38` に `edit`/`render :edit` があるがビューは index/show のみ → `MissingTemplate` で500。permit（`:assigned_to`/`:notes`）と実UIも乖離【事実】。

### 重複・未使用系

18. **重複実装群**【呼び出し元grepで事実】:
    - 記事公開ロジック3系統: `ArticlePublishingService`（コントローラ使用）／`ArticlePublishingManager`（状態判定delegateのみ。`schedule!`等は未使用、`update_related_counts` は `article.rb:142-153` と完全重複）／`Publishable` concern（Articleでは同名メソッド・スコープに上書きされ死にコード）
    - position管理3系統: `Positionable` concern／`MyStorySectionPositionManager`（delegate経由の呼び出し元ゼロ。かつ `:107` の `position: -1` がバリデーション違反で**呼べば必ず失敗**）／`MyStorySectionOrderingService`（実際に生きているのはこれだけ）
    - 記事検索4系統: `scope :search`（pg_search、blog使用）／`search_ilike`（呼び出しゼロ）／`search_by_content`（portfolio/API使用）／`ArticleFilterService#filter_by_search`（ILIKE再実装）。公開側とAPI側で検索挙動が不一致
    - `SlackNotifier` のクラスメソッド/インスタンスAPI二重実装（:160-177 vs :180-255）
19. **未使用コード群**【参照ゼロをgrepで事実確認】: `CacheMonitorService`、`Media::EditService`（`admin/media_controller.rb:121-139` がインライン再実装済み＝Service Object Pattern違反も併発）、`Media::GenerateVariantsJob`、`StructuredDataHelper` 全292行、`lazy_image_with_placeholder`／`iso8601_datetime`／`tag_cloud`／`category_navigation`、Articleスコープ `works`/`standard_blog`/`search_ilike`/`by_tags`、空の `contacts_helper.rb`。`Publishable` の `Section.published`／`Article.visible` は**呼べば即SQLエラーの地雷**（現在呼び出しなし）【事実】。

---

## 🟢 Low（要約）

| 項目 | 対象 | 備考 |
|---|---|---|
| git追跡された残骸 | `brakeman-report.html`/`.json`/`brakeman_report.html`（ローカル絶対パス=ユーザー名漏洩）、`config/database.old.yml`（dev用パスワード直書き）、`config/database.new.yml`、`app/views/portfolio/sections/_my-story.html.erb.bak`、`scripts/deploy.sh.bak`、`docker-compose.old.yml`、`HTTPS_RECOVERY.md`、`scripts/.DS_Store` | 削除のみ【git ls-filesで事実】 |
| ローカル残骸（git外だがzip配布で漏洩） | `backup_before_upgrade.sql`（**実AdminUserのemail+bcryptハッシュ、暗号化前contactsを含む**）、`test_data_backup.json`、`.env`/`.env.production` 実物、`*.backup` 群、`TOMORROW_SIMPLE_TEST.md` 等約10ファイル | 【事実】 |
| ページネーション等のマジックナンバー | `blog_controller.rb:23-49` の `.per(10)` 4箇所、`feeds_controller.rb:28` の `.limit(20)`、関連記事 `.limit(3)` ほか多数 | 設定化 or 定数化【事実】 |
| Kamalテンプレート残骸 | `config/deploy.yml`（`192.168.0.1`、`localhost:5555`） | 未使用と思われる【推測】 |
| PWA manifest未設定 | `manifest.json.erb`（name "PortfolioRb"、theme_color "red"）。レイアウトのリンク自体コメントアウト中 | 【事実】 |
| コピーライト年3実装 | `shared/_footer.html.erb:64`（©2024固定）／`blog/*`（©2025固定）／`portfolio/sections/_footer.html.erb:47`（動的） | 【事実】 |
| 不自然な例外回避ほか | `json_storable.rb:104`（`rescue nil`）、`api/internal/security_controller.rb:74-77`（no-op rescue→raise）、`bedrock_client.rb:107`（dev限定SSL検証無効） | 【事実】 |
| AdminUser emailバリデーション重複 | `admin_user.rb:13`（Devise :validatableと重複） | 【事実】 |
| テスト欠落（重要箇所） | restore系3サービス（`config_restore`/`database_restore`/`storage_restore`）、`article_filter_service`（検索=CLAUDE.mdでTDD必須領域）、`Admin::DashboardController` | 【事実】 |
| pg_trgm拡張にDB特権必要 | `db/migrate/20251230123023` | マネージドPGで詰まる可能性【推測】 |
| OTP暗号鍵がsecret_key_baseフォールバック | `admin_user.rb:7` | credentials再生成で既存2FA復号不能【推測】。渡している `otp_secret_encryption_key:` オプション自体devise-two-factor 6では未使用の可能性【推測】 |
| 静的ファイルのフォールバック404 | `site_assets_service.rb:101` の `"/images/default.jpg"`（`public/images/` は空） | 【事実】 |
| デバッグコメントのHTML出力 | `shared/_header.html.erb:14`（ロゴ設定状態をHTMLコメントで公開） | 【事実】 |
| scaffold残骸ビュー | `admin/site_settings/{show,edit,update}.html.erb`（"Find me in ..."） | 【事実】 |
| Contactフォームの件名選択肢が受託エンジニア前提 | `portfolio/sections/_contact.html.erb:51-57` | 【事実】 |
| 開発用DB認証情報のハードコード | `docker-compose.yml`（`portfolio_password`） | 開発用のため実害小【事実】 |
| `.gitignore` 内の存在しないファイル参照 | `config/initializers/aws_ses.rb.disabled` | 【事実】 |
| production.rb の死んだ設定 | `production.rb:66`（`host: "example.com"`、後段のENV設定で上書き） | 【事実】 |
| AWSリージョンのデフォルト不統一 | bedrock=us-east-1、s3/ses=ap-northeast-1 | ENV優先のため許容範囲【事実】 |

---

## ❓ 確認が必要な仕様（修正方針を確定していないもの）

> **回答欄付き。回答をもとにフェーズ1以降へ着手する。**

1. **予約投稿**（H-2）: 完成させるか、UIから削除するか。
   - 回答（2026-07-15）: **完成させる**（日時入力欄 + 自動公開ジョブを実装）。
2. **article_countの定義**（H-8）: 「公開記事数」か「全記事数」か。
   - 回答（2026-07-15）: ダッシュボードでは総記事数と公開記事数を分けて表示している（`dashboard_controller.rb:3-5` はカウンタカラムを使わずライブ集計【事実】）。
   - 補足（Claude Code）: 問題のカラムはtags/categoriesの `article_count`（公開サイトの `popular` スコープ等で使用）。ダッシュボードはこのカラムに依存していないため、**「公開記事数」に統一する方針を推奨**（公開ページの表示に使われるカウンタのため）。
3. **MyStory機能の位置づけ**（H-9/H-13）: 汎用機能化か、オプションモジュール化か、製品から除外か。
   - 回答（2026-07-15）: **汎用版では除外。現行モデルからも削除する方向で検討**（理由: クリックされていない）。削除時はセクション管理機能の見直しが必要。
4. **マルチユーザー・権限**（H-12）: 単一管理者製品として売るか、複数管理者+ロールを要件に入れるか。
   - 回答（2026-07-15）: **汎用版で複数管理者+ロールを要件に入れる**（現行モデルでは着手しない）。
5. **対応言語**（H-11）: 日本語専用として売るか、i18n対応するか。
   - 回答（2026-07-15）: **初期は日本語専用。将来的に多言語化を検討**。
6. **ジョブ基盤**（H-3/H-10）: Solid Queueに一本化でよいか。
   - 回答（2026-07-15）: 質問の意図の説明を受けて再判断（下記改訂セクション参照）。**推奨はSolid Queue一本化**。
7. **インフラ前提**: AWS固定でよいか。
   - 回答（2026-07-15）: **現状はAWS固定。将来的にSMTP・他ストレージ（さくらインターネット等）を検討**。
8. **販売形態とライセンス**（H-10）: ソースコード配布か、SaaSか。
   - 回答（2026-07-15）: **未検討。メリット・デメリットの整理を受けて後日判断**（下記改訂セクション参照）。汎用化着手までに決定すればよい。
9. **site_title等を空に戻せない挙動**（Medium-1）: gtm_idだけ空可能にする意図だったのか。
   - 回答（2026-07-15）: **意図的ではない。site_title等は必須であるべき**（＝gtm_idのみ空更新を許可する型別制御を実装する）。
10. **タグにdescription/color/iconを持たせるか**（C-4）: フォーム削除かカラム追加か。
    - 回答（2026-07-15）: **現行のSEO機能と融合させ、不要なものは削除する方向で検討**（当面はフォームから3フィールドを削除して500を解消し、タグのSEO設計は別途検討）。

---

## 🗺️ 修正ロードマップ（優先順位付き）

各フェーズは「前のフェーズが安全網になる」順。**フェーズ0を飛ばして修正に入らないこと**。

### フェーズ0: 安全網の確保（最優先・半日〜1日）

1. CIグリーン化: `markdown_helper_spec` 1件修正 + `action_text-trix` を2.1.18以上へ更新（既知XSS 2件）（H-14）
2. 本番DBの手動バックアップ取得
3. 開発環境で「推測(高確度)」とした500系（C-3, C-4, C-5, M-17）を実際に再現し、事実として確定

### フェーズ1: 即死バグ・セキュリティ修正（小さく確実な修正のみ）

4. `/test` 一式削除（C-6）
5. タグフォーム修正（C-4）※確認事項10の回答後
6. Contact FK修正（C-5）
7. `service`/`_services` 命名統一 + data migration（C-3）
8. `scripts/init_sections.rb` の削除 or スキーマ追随
9. robots.txt修正 + `DEFAULT_PATH` 変更（C-7）
10. og-default.jpg 差し替え（C-11）
11. rack_attackフォールバック修正（M-5）

各修正にregression specを必ず追加。

### フェーズ2: 新規環境インストール可能化

12. credentials再生成 + `db:encryption:init` の手順化とENVフォールバック（C-1, C-2）
13. seeds全面整備: 冪等化・My Story修正・サンプルデータ匿名化（H-4）
14. ADMIN_PASSWORD必須化(fail-fast)（H-5）
15. `.env.production.example`/READMEの配布物入り（H-6）
16. **受け入れ基準**: クリーンなDocker環境で「セットアップ→管理画面ログイン→記事公開→トップ表示→問い合わせ送信」が通るsystem spec（インストールスモークテスト）を新設

### フェーズ3: 開発者固有値の排除・設定化

17. SiteSettingキー拡張（著者・SNS・コピーライト・twitter_site・連絡先等）（C-8）
18. ビュー約30箇所・メール文面・フォールバック値の置換と統一（C-8, H-7, M-4）
19. S3デフォルトバケット削除（H-15）、ドメイン変数化（C-12）
20. **受け入れ基準**: 全公開ページ・メール出力に「miyakawa/宮川/Miyakawa Codes」が含まれないことのregression spec

### フェーズ4: 設定反映の信頼性

21. SiteSettingメモ化の廃止/是正（C-9）
22. admin_pathのconstraint方式への設計変更（C-10）※設計レビュー推奨
23. GTMクリア可能化・インポート後キャッシュクリア（M-1, M-2）

### フェーズ5: 整理・統合（挙動を変えないリファクタリング）

24. Sidekiq系gem削除 + recurring.yml一本化 + rotation登録検証（H-3, H-10）
25. 重複実装の統合（公開・position・検索・SlackNotifier）、未使用コード削除（M-18, M-19）
26. git残骸・ローカル残骸の削除（Low）
27. H-1のバリデーション反転修正（既存データ検証とセットで、このフェーズで慎重に）

### フェーズ6: 製品化対応（確認事項1〜8の回答が前提）

28. LICENSE策定、i18n方針実行、認可/マルチユーザー、My Story・セクション汎用化、AWS抽象化、H-8カウンタ仕様確定

---

**注記**: 本レポートは静的解析に基づく。「推測（高確度）」とした500エラー系はフェーズ0で実環境再現による確定を行うこと。

---

# 📝 改訂（2026-07-15）: 回答受領と二段階ロードマップ

## 基本方針の変更

**「現行モデルの完成度向上（ステージ1）→ 汎用化モデル（ステージ2）」の二段階で進める。**
上記の旧ロードマップ（フェーズ0〜6）は本セクションに置き換え。

## 追加された要望（2026-07-15）

- **要望1: 記事プレビュー機能が未完成** — 管理画面の記事詳細（`app/views/admin/articles/show.html.erb:87-89`）が本文を `<pre>` で生表示。「※ Markdownのプレビュー機能は後日実装予定です」のコメントあり【事実】。公開側の描画ヘルパー `markdown_with_ogp_cards`（`blog/show.html.erb:110` で使用）を管理画面でも使えば小工数で実装可能。
- **要望2: MyStory機能を現行モデルから削除する方向で検討** — 理由: クリックされていない。削除時はセクション管理機能の見直しが必要。

## MyStory削除の波及効果（重要）

MyStoryを削除すると、監査指摘のうち以下が**修正不要（削除で消滅）**になる:

- H-1（バリデーション反転）、H-9（attr_accessorカラム隠蔽）、H-13（個人キャリア定数）、H-4の大半（seed問題）
- 未使用・重複の相当部分: `my_story_section_*` サービス7ファイル、position管理3系統のうち2系統、C-8の直書き箇所のうち `_my-story.html.erb`・`my_story/index.html.erb` 系

削除対象の概算スコープ【事実確認済みの構成要素】: `MyStorySection` モデル + サービス7ファイル + `Admin::MyStorySectionsController` + `MyStoryController`（公開ページ `/my-story`）+ ビュー群 + seed + ルーティング + `my_story_sections` テーブル + ポートフォリオトップの `my-story` セクション（Sectionレコード + `_my-story.html.erb` パーシャル）+ 対応spec群。
**先にMyStory削除を確定させてから他の修正に入ると、無駄な修正作業を大きく削減できる。**

## Q6（ジョブ基盤）の説明と推奨

- ジョブ基盤 = メール送信・バックアップなど「画面の裏で後から実行する処理」を担う仕組み。
- 本アプリには **Sidekiq**（別途Redisサーバーが必要。ライセンスはLGPL-3.0）と **Solid Queue**（Rails 8標準。PostgreSQLだけで動く。MIT）の両方のgemが入っているが、**実際に動いているのはSolid Queueのみ**（本番composeにRedis/Sidekiqサービスなし【事実】）。
- スケジュール定義が3ファイル（`recurring.yml`/`queue.yml`/`sidekiq_cron.rb`）に重複し時刻も食い違っている。
- **推奨**: Sidekiq系gem（sidekiq/sidekiq-cron/sentry-sidekiq/redis）を削除しSolid Queueに一本化。Redis不要になり構成が単純化、LGPL懸念も消滅、スケジュールは `recurring.yml` 1ファイルに。デメリットは実質なし（超大量ジョブではSidekiq有利だが本CMSの規模では無関係）。

## Q8（販売形態）の比較整理

| 観点 | ソースコード配布（買い切り） | SaaS（自社ホスティング・月額） |
|---|---|---|
| 収益 | 単発。1本ごとに売上 | 継続（MRR）。立ち上がりは遅い |
| インストール問題（C-1/C-2） | **必須対応**（顧客が自分で構築） | ほぼ不要（自分の環境だけ動けばよい） |
| 運用責任 | 顧客側（サポート問い合わせは来る） | 全部自分（監視・障害・バックアップ・個人情報保護） |
| 必要な追加開発 | インストーラ/手順書・アップデート配布 | **マルチテナント化（大改修。現設計はシングルテナント）** |
| コード保護 | 流用・転売リスクあり。ライセンス設計が重要 | 非公開のまま |
| 中間形態 | セットアップ代行付き配布、テーマ販売、オープンコア | — |

**判断は汎用化（ステージ2）着手時までで足りる。** ただし「配布」なら旧フェーズ2（インストール可能化）が必須、「SaaS」ならマルチテナント設計が必須、という分岐だけ意識しておく。

## 改訂ロードマップ

### ステージ1: 現行モデルの完成（このサイト自体の品質向上）

- **S1-0. 安全網**: CIグリーン化（markdown_helper_spec 1件 + action_text-trix ≥2.1.18）、本番バックアップ、500系（C-3/C-4/C-5/M-17）の実環境再現
- **S1-1. MyStory削除の確定と実施**（要望2）: 影響調査 → セクション管理の見直し設計 → 削除。※他の修正より先に行うと後工程が軽くなる
- **S1-2. 即死バグ・セキュリティ**: `/test` 削除（C-6）、タグフォーム3フィールド削除（C-4/回答10）、Contact FK修正（C-5）、`service`/`_services` 統一（C-3）、`init_sections.rb` 対応、robots.txt + `DEFAULT_PATH`（C-7）、og-default.jpg（C-11）、rack_attack修正（M-5）
- **S1-3. 未完成機能の完成**:
  - 記事プレビュー実装（要望1。公開側ヘルパーの流用）
  - 予約投稿の完成（回答1。`published_at` 入力欄 + 自動公開ジョブ + recurring登録）
  - article_count を公開記事数に統一 + 再計算タスク（回答2の補足方針。要最終確認）
  - site_title等は必須維持・gtm_idのみ空更新可に（回答9）
- **S1-4. 設定反映の信頼性**: SiteSettingメモ化是正（C-9）、admin_path constraint化（C-10）、site_title全ページ反映（H-7）、インポート後キャッシュクリア（M-2）
- **S1-5. 整理**: Solid Queue一本化（回答6）、重複実装統合・未使用コード削除（M-18/19）、git残骸削除、2FAデッドフロー整理（M-3）

### ステージ2: 汎用化モデル（第三者配布用）

- **S2-1. インストール可能化**: credentials/暗号鍵手順（C-1/C-2）、seeds匿名化・冪等化、ADMIN_PASSWORD fail-fast、`.env.production.example`/README、インストールスモークテスト
- **S2-2. 開発者固有値の排除**: SiteSettingキー拡張 + ビュー置換（C-8）、S3デフォルト削除（H-15）、ドメイン変数化（C-12）
- **S2-3. マルチユーザー + ロール**（回答4）: Pundit本格導入、`dependent: :destroy` 見直し
- **S2-4. 製品化**: 販売形態決定（Q8）→ LICENSE策定、日本語専用と明記（回答5）、AWS前提の明記（回答7）
- （将来）多言語化、SMTP/他ストレージ対応

## S1-0 実施記録（2026-07-15）

- **CIグリーン化 完了**:
  - `markdown_helper_spec` 修正: 実装は仕様どおり（URL→OGPカード置換が動作）で、テストの期待値が逆だったため期待値側を修正
  - セキュリティ更新: bundler-audit検出の**34件すべて解消**。Rails 8.1.1→8.1.3、Devise 4.9.4→**5.0.4（メジャー）**、devise-two-factor 6.3.1→6.4.0、Puma 7.1.0→**8.0.2（メジャー）**、action_text-trix 2.1.16→2.1.19 ほか
  - 検証: RSpec全1,264件グリーン（Devise 5互換確認）、Puma 8起動+`/up`ヘルスチェック200確認
- **500系バグの実環境再現 完了**: `spec/requests/audit_regression_spec.rb` にpending付き回帰テストとして固定
  - C-3（serviceパーシャル不在）: 再現【事実確定】
  - C-4（タグフォーム）: 再現。`undefined method 'color' for Tag`【事実確定】
  - **C-5は重要度修正 Critical→High**: `includes(:admin_user)` は例外を出さず一覧は表示できる（監査の500予測は外れ）。ただし `update(assigned_to:)` は `UnknownAttributeError`、`assigned_to_id` を直接設定しても関連は常にnilで、**アサイン機能自体は完全に死んでいる**【実行時検証で事実確定】
  - M-17（contacts editテンプレ不在）: 再現【事実確定】
- **未実施**: 本番DBの手動バックアップ（本番サーバーへのアクセスが必要なため、プロジェクトオーナーによる実施が必要）

## S1-1 実施記録（2026-07-15）

**スコープ確定**: 剛さんの指示により「MyStory**独立ページ**（`/my-story` + `MyStorySection` システム）のみ削除。トップページの My Story **セクション**（SectionContentベース）は存続」。

- **削除**: `MyStoryController`・`Admin::MyStorySectionsController`・`MyStorySection` モデル・サービス7ファイル・ビュー2ディレクトリ・spec 10ファイル+ファクトリ・seed 5ファイル・rakeタスク・JSコントローラ・`_my-story.html.erb.bak`（計約35ファイル）
- **マイグレーション**: `20260715000000_drop_my_story_sections.rb`（reversible。本番はデプロイ時のdb:prepareで適用、データはS3日次バックアップで保全）
- **旧URL対策**: `/my-story` → `/#my-story` へ301リダイレクト + 回帰spec（`spec/requests/my_story_redirect_spec.rb`）
- **これで消滅した監査指摘**: H-1（バリデーション反転）、H-9（attr_accessorカラム隠蔽）、H-13（個人キャリア定数）、H-4の大半、M-18のposition管理2系統、M-19の一部
- **付随対応**: `JsonStorable` concernがどのモデルからも未使用になったため削除。`publishable_spec` のテスト用ホストをPOROに置換。フッターの元から壊れていたアンカー `#my_story`（正: `#my-story`）を修正
- **検証**: RSpec全1,229件グリーン（1,264→削除分減、失敗0）

## S1-2 実施記録（2026-07-15）

8件すべて修正完了。回帰テスト（audit_regression_spec）のpendingは全解除。全1,230specグリーン。

- **C-6**: `/test` 一式削除（ルート・コントローラ・モデル・`test_items`テーブルdrop・seed・spec）
- **C-4**: タグフォームから存在しない3フィールド削除。**併せて発見・修正**: `Tag#to_param`がslugを返すのにコントローラが`Tag.find`（ID検索）で、編集リンクが404になる不整合 → slug検索に統一。既存specが`.id`明示渡しでバグを回避していたのも正規形に修正
- **C-5**: `foreign_key: :assigned_to_id` へ修正、permitも統一。アサイン機能がコントローラ経由で動作することをspecで検証
- **M-17**: テンプレート不在のeditアクション/ルートを削除、update失敗はshowへリダイレクトに変更。「MissingTemplateが発生すること」を期待していた既存specも正常系に書き換え
- **C-3**: パーシャルを`_service.html.erb`にリネームし'service'で統一。既存DBの'services'を直すdata migration追加。壊れていた`scripts/init_sections.rb`を削除し、entrypointは冪等なdb:seedに一本化
- **C-7**: robots.txtから管理パスのDisallow削除、nginxの`/admin`→秘密パス301（秘匿の自己否定）削除、`DEFAULT_PATH="admin"`へ変更、deploy.shの秘密パスecho削除、`deploy.sh.bak`削除。**残課題**: docs/reports内に旧パスの記載が多数残るため、本番の管理パス自体を変更（ローテーション）することを推奨
- **C-11**: `og-default.jpg` を実JPEG（1200x630、ブランド要素なし）に差し替え + マジックバイト検証spec
- **M-5**: rack_attackを「REDIS_URLがある本番のみRedis、他はMemoryStore」の正しい分岐に修正
- **発見**: `.rspec` に `--fail-fast` があり、全件実行は失敗ゼロの時のみ完走する挙動（CI解釈時に注意）

**デプロイ前チェック（本番）**: `.env.production` に `ADMIN_PATH` が設定されているか、または `AdminPathHistory` にレコードがあるかを確認。どちらも無い場合、デプロイ後の管理画面URLは `/admin` に変わる（DEFAULT_PATH変更のため）。

## S1-3 実施記録（2026-07-15）

未完成機能4件を完成。全1,253specグリーン。

- **S1-3a（回答9）**: SiteSettingのtext型バリデーションに `optional` フラグを導入。gtm_idのみ空更新可（＝GTM無効化が可能に）、site_title/site_descriptionは必須維持
- **S1-3b（要望1）**: 管理画面の記事詳細を公開側と同じ `markdown_with_ogp_cards` 描画に変更（「後日実装予定」コメントを撤去）。フォームの文言も更新
- **S1-3c（回答2）**: article_count = 公開記事数に統一
  - `Category#refresh_article_count!` / `Tag#refresh_article_count!` に一元化
  - ArticleTagにコールバック追加（タグ解除時の更新漏れ解消）、ArticleCategoryの全件カウントを公開数に修正
  - **has_many :throughの一括置換はjoinコールバックが発火しない**ことを実測で確認 → Articleの `category_ids=`/`categories=`/`tag_ids=`/`tags=` をオーバーライドし、外された側も更新
  - Categoryの親ロールアップ（`update_parent_article_count`）は`update_column`起点では発火しない完全な死にコードだったため削除
  - ArticlePublishingManagerの重複カウント処理を削除、Articleのafter_saveは公開状態変化時のみに限定
  - 再計算タスク `article_counts:recalculate` 追加（本番デプロイ後に1回実行を推奨: 既存カウントを正しい定義で再計算）
  - 新spec: `spec/models/article_count_spec.rb`（12例）
- **S1-3d（回答1）**: 予約投稿を完成
  - フォームに公開日時（datetime-local）入力欄、permitに `:published_at` 追加
  - バリデーション: scheduledは published_at 必須（宙に浮く状態を防止）
  - `PublishScheduledArticlesJob` 新設 + recurring.yml（本番・5分間隔）登録
  - 既存 `publish_scheduled_articles!` が予約時刻を実行時刻で上書きするバグを発見・修正（予約時刻を維持）
  - 新spec: `spec/jobs/publish_scheduled_articles_job_spec.rb`（6例、recurring.yml登録検証含む）

**本番デプロイ後の作業**: `docker compose exec web bin/rails article_counts:recalculate` を1回実行（既存カウントの再計算）。

**S1-3追加対応（動作テスト中の発見、2026-07-15）**:
- 記事抜粋がエスケープされ `<p>` タグが文字表示されるバグを修正（`sanitize_html` がhtml_safeを付けていなかった。本文用ヘルパーだけ付けていて抜粋用は漏れ）
- トップページのブログセクションのダミー記事プレースホルダー（「2024年12月05日」「サンプル記事タイトル」の偽カード3枚）を削除し、「記事はまだありません」表示に変更。実在しないコンテンツが本物に見えるUIは誤解の元（今回、DB参照先ズレの疑い調査の原因になった）
- 検証で確認した事実: dev環境のDB参照はDocker `db` コンテナで正常。予約公開ジョブはdevでは手動実行（`PublishScheduledArticlesJob.perform_now`）、本番は5分間隔の自動実行

## 障害記録: 本番トップページ500（2026-07-15、デプロイ直後）

- **事象**: S1-0〜S1-3デプロイ後、トップページのみ500（/up・/blog・/my-storyは正常）
- **原因**: 本番DBに旧init_sections.rb製の `services`（実コンテンツ入り）とseeds.rb製の `service`（空）が並存。C-3対応のマイグレーション（20260715000003）のガード条件「`service` が存在すればリネームしない」が並存パターンで裏目に出て、実コンテンツ側が旧名のまま残置。`_services.html.erb` は削除済みのため MissingTemplate
- **復旧**: rails runnerで空の `service` を削除し `services` → `service` にリネーム（即時復旧）
- **再発防止**: 並存パターンを自動修復するマイグレーション追加（20260715120000。両方にコンテンツがある場合は明示的に失敗して手動統合を促す）+ 再現テスト4例（`spec/migrations/`）
- **教訓**: (1) データ移行のガード条件は「守りたい対象は何か」を確認してから書く（今回守るべきは実コンテンツで、名前の先取りではなかった）。(2) 本番DBの実データ分布はローカル/seedsと異なる前提で、デプロイ前に本番データの状態確認クエリを用意する。(3) コミット≠プッシュ。デプロイ前にリモート反映を確認する
- **付随判明**: `.env.production` の ADMIN_PATH は旧パスと同値で設定されていた（→ 新パスへの変更を推奨済み）

## 未確定の判断事項

1. ~~MyStory削除の最終確定~~ → **確定（2026-07-15）: 完全廃止**。理由: クリックされていない・記事が長すぎる・indexと内容が被る
2. ~~article_count統一~~ → **確定（2026-07-15): 公開記事数で統一**
3. ~~Solid Queue一本化~~ → **確定（2026-07-15）: 承認済み**
4. 販売形態（ステージ2着手時までに）
5. タグのSEO設計（当面はフォーム修正のみ、融合設計は別途）
