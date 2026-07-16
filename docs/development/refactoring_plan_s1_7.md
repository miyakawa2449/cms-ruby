# S1-7 リファクタリング計画

- **作成日**: 2026-07-16（S1-5完了時の全体検証に基づく）
- **調査方法**: 3並列エージェント（設計負債／ビュー・パフォーマンス／テスト品質）+ S1-5からの繰越項目
- **実施時期**: S1-6（パスキー導入）の後
- **原則**: 挙動を変えない（バグ修正を除く）。修正単位ごとにテスト→全suite→コミット。P0以外は着手前に対象ファイルの現状を再確認する（S1-6で変わる可能性があるため）

---

## P0: 即効バグ修正（S1-7初日に一括で）

> **2026-07-16 第1弾完了・本番デプロイ済み・剛さん稼働確認済み**: P0-1〜P0-5、P3-1(b)、P4-1を実施（コミット2a41a75〜5958173）。incidents実測値が入る初回レポートは2026-07-20(月)10:00の週次生成分。
> 次は第2弾（P1-1〜P1-5 + P5-2）。着手前に「要確認事項」の①unpublish時のpublished_at扱い・②管理画面検索の方式を剛さんに確認すること。
> - P0-4は剛さんの判断で「削除ではなく計測を実装」: SecurityEventテーブル新設（要マイグレーション）+ SecurityLoggerのDB永続化 + CSRFフック + Rack::Attackのblocklist/throttle区別記録 + 90日パージ（recurring.yml）
> - P0-4の副産物としてContactsControllerの `protect_from_forgery` 再宣言がHTML POSTのCSRF検証を無効化していた穴を発見・修正（JSONもトークン必須に統一。正規クライアントはX-CSRF-Token送信済みのため影響なし）
> - P0-5の副産物: libvips不在だとActive Storageの画像解析が黙って空になるため、Mac（brew install vips）とCI（libvips42）に導入。本番Dockerイメージは元々libvipsあり

| # | 内容 | 対象 | 規模 |
|---|---|---|---|
| P0-1 | トップページの**無限retry**修正（DB障害時にPumaワーカーを食い潰す）+ 全体rescueで空ページ200を返す設計の撤去 | `portfolio_controller.rb:40-44` | 小 |
| P0-2 | `ArticleStatisticsService#calculate` 系の削除（groupdate gem不在で**呼ぶと必ず落ちる**。呼び出し元ゼロ確認済み。使用中の`index_stats`のみ残す） | `article_statistics_service.rb:5-46` | 小 |
| P0-3 | `ArticleSerializer` の `og_image_url` デッドフィールド修正（delegateに無いため常にnil。delegate追加 or 項目削除） | `article_serializer.rb:42` | 小 |
| P0-4 | `Security::ReporterService` の常時0を返すスタブ4メソッド（週次レポートのincidentsが**計測しているように見えて常にゼロ**）→ 実装するか項目を削除するか判断して対応 | `security/reporter_service.rb:116-135` | 小〜中 |
| P0-5 | `Admin::ArticleImagesController` が実画像を解析せず定数800x600をメタデータ保存している問題の修正 | `article_images_controller.rb:79-80` | 小 |

## P1: 重複実装の統合

| # | 内容 | 方針 | 規模 |
|---|---|---|---|
| P1-1 | **記事検索の統合** | `Article.search`（pg_search）を正とし `search_by_content` を置換・削除。`ArticleFilterService` のfilter系はArticleスコープ呼び出しに寄せ、`defined?(Kaminari)` ガード削除。※管理画面だけILIKE維持するかは要判断（下記「要確認」） | 小 |
| P1-2 | **SlackNotifier統合** | クラスメソッドAPIを正とし `notify_contact(contact)` を追加、インスタンスAPI削除。失敗時も通知レコードを作る挙動（インスタンス側）に統一。不要な `include HTTParty` 削除 | 小 |
| P1-3 | **タグ生成の一本化** | `Tag.find_or_create_by_name!` をモデルに定義。`ArticleAssociationService` は実質 `setup_for_form` だけなのでサービスごと削除しコントローラへ | 小 |
| P1-4 | **アップロード検証定数の一元化** | `MAX_FILE_SIZE`/許可MIMEの3重定義を `MediaValidatable` に集約。ArticleImagesControllerの独自検証をUploadService利用に寄せる | 小 |
| P1-5 | **AI統計の一本化** | `Ai::UsageTracker` は記録専任に縮小、集計は `Ai::UsageStatisticsService` へ。丸め桁も統一 | 中 |
| P1-6 | **記事公開ロジックの統合**（最重要） | `ArticlePublishingManager` を正とし: (1)Serviceを削除しコントローラはManagerの `{success:}` 返却版を使用 (2)Manager内の未使用analytics/can_*系約80行を削除 (3)`Publishable` を解体し `visible` スコープのみの concern へ縮小（`Section.published` のSQL地雷も消滅）。**unpublish時にpublished_atをリセットするか要仕様確認**（Service=リセット、Manager=温存で現在不一致） | 中 |

## P2: 構造改善

| # | 内容 | 規模 |
|---|---|---|
| P2-1 | **Article Manager層の解体**（P1-6完了後）: ContentManager/MetaManagerの**過半が呼び出し元ゼロ**。未使用削除→残る属性系ロジック（tech_stack_list、slug生成、SEOフォールバック）はArticle本体か小さなconcernへ。delegate 21個を実使用分まで縮小。og_titleの「編集フォームにフォールバック値が焼き込まれる」問題（監査M-12）もここで解消 | 大 |
| P2-2 | **Admin::MediaController分割**（319行・責務5つ）: 保存系を`Media::ImageEditService`へ、フィルタはスコープ合成へ、JSONはシリアライザへ。`find_articles_using_media` の全記事Ruby走査をSQL化 | 大 |
| P2-3 | **SiteSetting 3Manager統合**: TypeManager/ValueManagerをモデルへ吸収（CacheManagerのみ残す）。設定6項目に対し現状4ファイルは過剰 | 中 |
| P2-4 | **エラーハンドリング規約の制定**: 「コントローラ向けServiceは`{success:, message:}`／job・バッチは例外」の2原則を conventions.md に明記し、触るファイルから漸進適用（一斉変更はしない） | 各小 |
| P2-5 | **サービス命名規約**: 「名前空間+役割名詞、エントリポイントは`call`」を標準と宣言（conventions.md）。一括リネームはせず新規・変更時に適用 | 各小 |
| P2-6 | バックアップ系の改善: 共通処理の基底クラス抽出（3重複・約60行削減）、素の`raise "文字列"`を`Backup::Error`階層へ、**リストア時のchecksum検証追加**（現状ダウンロード後未検証）、リストア実行前の確認トークン導入 | 中 |

## P3: ビュー・パフォーマンス

| # | 内容 | 規模 |
|---|---|---|
| P3-1 | **トップページのN+1解消**: (a)~~Worksセクションのビュー内クエリ~~→**2026-07-16対応済み**（剛さん報告の表示順ランダムバグ=ORDER BY欠落の修正と同時に、コントローラ移動+プリロード+COUNT解消を実施。コミット630af68） (b)Blogセクションの`tags.limit(4)`/`tags.count`→`first(4)`/`size`（プリロード有効化）は**未対応・残存** | 小 |
| P3-2 | admin一覧の調整: categories一覧は`article_count`カラム利用（※「公開記事数」定義のため削除可否判定の意味変化に注意）、tags一覧の過剰な`includes(:articles)`削除 | 小 |
| P3-3 | **記事カードのパーシャル統合**（4箇所コピペ・既に読了時間等が乖離）+ `Article#reading_time_minutes`/`#plain_text_excerpt`のモデル化（全文Markdownレンダリングを抜粋のために10回/頁 実行している問題も解消） | 中 |
| P3-4 | **ヘッダー/フッター統合**: `shared/_header`を正としportfolioバリアントのナビを現行に更新、モバイルメニューをパーシャル抽出、blog/index・showの独自フッターと`©年`の4箇所3方式を`shared/_footer`+動的年に統一。**S2のサイト名設定キー対応と同一作業で実施**（二度手間防止） | 中 |
| P3-5 | デッドビュー削除: `shared/_footer.html.erb`（render元ゼロ）、`portfolio/sections/_footer.html.erb`（※本番DBにfooterセクションが無いこと要確認）、`_about.html.erb.backup` | 小 |
| P3-6 | パンくず・ステータスバッジ・統計カードのパーシャル/ヘルパー化 | 小 |
| P3-7 | `admin/articles/_form.html.erb`（520行）のパーシャル分割 | 中 |
| P3-8 | **MarkdownRenderer のサービス化**: 3メソッドのレンダラー設定重複解消+Redcarpetメモ化+`ApplicationController.render`の逆流解消。OGPカードの描画時同期fetch（キャッシュミス時に記事表示がブロック）はfragment cache→将来は保存時取得ジョブへ。**XSS回帰テスト必須のため独立コミット** | 中 |
| P3-9 | フォールバック文言の一元化（`config/section_defaults.yml`またはi18n化、`||`全廃、未設定セクションは非表示）。**S2の個人文言削除と一体で実施** | 中〜大 |

## P4: JavaScript

| # | 内容 | 規模 |
|---|---|---|
| P4-1 | 未使用Stimulusコントローラ削除: `image_upload`(160行)/`confirm_dialog`/`two_factor_verify`/`hello` + 登録行（削除後にesbuild再ビルド。2FAは動作確認してから） | 小 |
| P4-2 | `article_image_upload_controller.js`(124行・未登録未参照)の要否確認→削除 | 小 |
| P4-3 | `ai_assistant_controller.js`(620行)のAPI通信部分離・機能別整理 | 中〜大 |

## 障害記録: specによるdev実storage/削除事故（2026-07-16）

- **事象**: dev環境のメディアライブラリ・記事の画像ファイルが消失（DBレコードは残存、ファイルのみ）。本番影響なし（ローカル完結）
- **原因**: `storage_backup_service_spec` の「storage/が存在しない場合」contextが実 `Rails.root/storage` を `rm_rf`。`active_storage_import_service_spec` も実storageを退避→afterで退避先ごと削除。`active_storage_export_service_spec` は実storageへ書き込み汚染。プロジェクトはコンテナへbind mountされているためdev実体が消えた。suite実行のたびに再発していた
- **性質**: S1-5の「restore specが実.envを破壊」と同一クラス（破壊的サービスのspecがRails.rootを差し替えていない）。P5-4/P5-6として後回しにしていた領域が先に顕在化した
- **対処**（076c18c）: 3specを既存の隔離パターン（`allow(Rails).to receive(:root)` + `Dir.mktmpdir`）で修正。`spec/support/real_storage_guard.rb`（番兵）を追加し、実storage/がテストで変更されたらsuite終了時に失敗させる。番兵ファイルを置いた全suite実行で無傷を確認済み
- **消失データ**: 復元不可（退避残骸なし）。剛さん判断で対処不要（テスト用画像のため）。孤児レコードは残置
- **教訓**: `storage/`・`.env`・`config/` 等の実ファイルを操作するサービスのspecは、必ずfake_root隔離+番兵ガードをセットで導入する

## P5: テスト品質

| # | 内容 | 規模 |
|---|---|---|
| P5-1 | ~~restore specの実`.env`破壊~~ → **S1-5で緊急修正済み**（fake_root隔離+番兵検証） | 完了 |
| P5-2 | `article_filter_service` の専用spec追加（5軸フィルタ×境界値。CLAUDE.mdのTDD必須区分）— P1-1の統合とセットで | 中 |
| P5-3 | `capybara.rb` の全system specに効くグローバル `Blob#image?` スタブ撤去（メディアアップロードE2Eの検証価値を回復。CIで確認） | 小〜中 |
| P5-4 | `media_spec` のバリデーションスタブ+`save!(validate: false)`をfixture画像ベースに置換 | 中 |
| P5-5 | `backups_spec` の不要なbefore_actionスタブ削除、`Admin::Dashboard` のrequest spec追加 | 小 |
| P5-6 | `restore_service_spec` の`File`クラス全体スタブと`receive_message_chain`（28箇所/12ファイル）の削減 | 中 |
| P5-7 | `.rspec` の `--fail-fast` 撤去 + spec_helper推奨設定（persistence file等）の有効化。~~BCrypt MIN_COST~~ → **S1-5で適用済み** | 小 |
| P5-8 | CIの残骸整理: minitest系ジョブ（`test`/`system-test`、対象0件）の削除 | 小 |

---

## 実施順序の推奨

```
第1弾: P0全部 + P3-1 + P4-1（即効・低リスク・削除中心）
第2弾: P1-1〜P1-5 + P5-2（統合・小粒）
第3弾: P1-6 → P2-1（公開ロジック→Manager解体。依存関係あり）
第4弾: P3-3 → P3-7 → P2-2（ビュー共通化→フォーム分割→Media分割）
第5弾: P2-3 + P3-8 + P5-3〜P5-6
S2連携: P3-4 / P3-9 は汎用化フェーズの個人文言削除と同一作業で
```

## 要確認事項（着手前に剛さんへ質問）

1. **unpublish時に`published_at`をリセットすべきか**（現状2実装で不一致。P1-6の前提）
2. **管理画面の記事検索**をpg_search（あいまい・再現率広い）に統一してよいか、管理画面だけILIKE（正確な部分一致）を残すか
3. `article_image_upload_controller.js` は将来使う予定のある機能か（未登録・未参照）
4. 本番DBのsectionsに `footer` レコードが存在するか（P3-5の前提）
5. ~~`Security::ReporterService` の失敗ログイン集計（現状常にゼロ）は実装したいか、レポート項目から外すか~~ → **2026-07-16回答済み: 計測できるように実装（P0-4で対応完了）**
