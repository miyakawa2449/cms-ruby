# Gem依存関係ドキュメント

## 概要
本ドキュメントは、ポートフォリオサイトプロジェクトで使用するGem（Ruby ライブラリ）の依存関係と各Gemの役割を説明します。

## Ruby バージョン
- **Ruby 3.4.0** （2024年12月25日リリース版）

## 主要フレームワーク

### Rails関連
| Gem名 | バージョン | 用途 |
|-------|-----------|------|
| rails | ~> 8.0.1 | Webアプリケーションフレームワーク |
| turbo-rails | latest | Hotwire SPA風ページ遷移 |
| stimulus-rails | latest | 軽量JavaScriptフレームワーク |
| propshaft | latest | アセットパイプライン |

### データベース
| Gem名 | バージョン | 用途 |
|-------|-----------|------|
| pg | ~> 1.1 | PostgreSQLアダプター |
| pg_search | ~> 2.3 | PostgreSQL全文検索機能 |

## 認証・認可

| Gem名 | バージョン | 用途 | 使用場所 |
|-------|-----------|------|----------|
| devise | ~> 4.9 | ユーザー認証システム | 管理画面ログイン |
| jwt | ~> 2.7 | JSON Web Token | API認証 |
| pundit | ~> 2.3 | 認可（権限管理） | ロールベースアクセス制御 |

### Devise設定項目
- ログイン試行回数制限（5回）
- アカウントロック機能（30分）
- セッション管理
- パスワードリセット機能

## バックグラウンド処理

| Gem名 | バージョン | 用途 |
|-------|-----------|------|
| sidekiq | ~> 7.2 | 非同期ジョブ処理 |
| sidekiq-cron | ~> 1.12 | 定期ジョブスケジューラー |
| redis | >= 4.0.1 | Sidekiqバックエンド・キャッシュ |
| redis-rails | ~> 5.0 | Rails Redisキャッシュ統合 |

### Sidekiq使用箇所
- AI記事分析処理
- 画像変換・最適化
- メール送信
- 定期バックアップ
- サイトマップ生成

## AI・外部API連携

| Gem名 | バージョン | 用途 |
|-------|-----------|------|
| ruby-openai | ~> 6.3 | OpenAI API (ChatGPT) クライアント |
| httparty | ~> 0.21 | HTTPクライアント（汎用） |

### OpenAI API機能
- 記事要約生成
- SEOキーワード抽出
- 関連記事提案
- コンテンツ分析

## 画像処理・ファイル管理

| Gem名 | バージョン | 用途 |
|-------|-----------|------|
| image_processing | ~> 1.2 | Active Storage画像バリアント |
| carrierwave | ~> 3.0 | ファイルアップロード管理 |
| mini_magick | ~> 4.12 | ImageMagick Ruby wrapper |
| fog-aws | ~> 3.21 | AWS S3ストレージ連携 |

### 画像処理機能
- WebP自動変換
- リサイズ・最適化
- 遅延読み込み対応
- S3アップロード

## SEO・メタデータ管理

| Gem名 | バージョン | 用途 |
|-------|-----------|------|
| meta-tags | ~> 2.20 | メタタグ動的生成 |
| sitemap_generator | ~> 6.3 | XMLサイトマップ生成 |
| friendly_id | ~> 5.5 | SEOフレンドリーURL（slug） |

## セキュリティ

| Gem名 | バージョン | 用途 |
|-------|-----------|------|
| rack-attack | ~> 6.7 | レート制限・DDoS対策 |
| rack-cors | ~> 2.0 | CORS設定（API用） |
| brakeman | ~> 6.1 | セキュリティ脆弱性静的解析 |

### Rack::Attack設定
- ログイン試行制限
- API レート制限
- IP ホワイトリスト/ブラックリスト

## API開発

| Gem名 | バージョン | 用途 |
|-------|-----------|------|
| active_model_serializers | ~> 0.10.14 | JSON APIシリアライザ |
| kaminari | ~> 1.2 | ページネーション |
| api-pagination | ~> 5.0 | APIレスポンスページング |
| jbuilder | latest | JSON レスポンス構築 |

## コンテンツ処理

| Gem名 | バージョン | 用途 |
|-------|-----------|------|
| redcarpet | ~> 3.6 | Markdownパーサー |
| rouge | ~> 4.2 | シンタックスハイライト |

### Markdown設定
- GitHub Flavored Markdown対応
- コードブロックハイライト
- テーブル・チェックリスト対応

## フロントエンドアセット

| Gem名 | バージョン | 用途 |
|-------|-----------|------|
| cssbundling-rails | latest | CSS バンドル（Tailwind CSS） |
| jsbundling-rails | latest | JavaScript バンドル |

## 監視・ロギング

| Gem名 | バージョン | 用途 |
|-------|-----------|------|
| lograge | ~> 0.14 | 構造化ログ出力 |
| sentry-rails | ~> 5.15 | エラー監視・レポート |
| sentry-sidekiq | ~> 5.15 | Sidekiqエラー監視 |

## 開発環境専用 Gem

### デバッグ・開発効率化
| Gem名 | バージョン | 用途 |
|-------|-----------|------|
| debug | latest | デバッガー |
| better_errors | ~> 2.10 | エラー画面改善 |
| binding_of_caller | ~> 1.0 | エラー時REPL |
| web-console | latest | ブラウザ内コンソール |
| rack-mini-profiler | latest | パフォーマンス分析 |

### コード品質
| Gem名 | バージョン | 用途 |
|-------|-----------|------|
| rubocop | ~> 1.60 | Rubyコード規約チェック |
| rubocop-rails | ~> 2.23 | Rails専用規約 |
| rubocop-rspec | ~> 2.26 | RSpec規約 |
| annotate | ~> 3.2 | モデルスキーマ注釈 |
| bullet | ~> 7.1 | N+1クエリ検出 |
| rails-erd | ~> 1.7 | ER図自動生成 |

### その他開発ツール
| Gem名 | バージョン | 用途 |
|-------|-----------|------|
| letter_opener | ~> 1.8 | 開発環境メール確認 |
| dotenv-rails | ~> 2.8 | 環境変数管理 |

## テスト環境専用 Gem

### テストフレームワーク
| Gem名 | バージョン | 用途 |
|-------|-----------|------|
| rspec-rails | ~> 6.1 | BDDテストフレームワーク |
| capybara | latest | 統合テスト |
| selenium-webdriver | latest | ブラウザ自動操作 |

### テストサポート
| Gem名 | バージョン | 用途 |
|-------|-----------|------|
| factory_bot_rails | ~> 6.4 | テストデータ生成 |
| faker | ~> 3.2 | ダミーデータ生成 |
| shoulda-matchers | ~> 6.0 | RSpecマッチャー拡張 |
| database_cleaner-active_record | ~> 2.1 | テストDB管理 |

### モック・スタブ
| Gem名 | バージョン | 用途 |
|-------|-----------|------|
| webmock | ~> 3.19 | HTTP通信モック |
| vcr | ~> 6.2 | HTTPレスポンス記録・再生 |
| simplecov | ~> 0.22 | テストカバレッジ計測 |

## その他ユーティリティ

| Gem名 | バージョン | 用途 |
|-------|-----------|------|
| whenever | ~> 1.0 | cron設定管理 |
| geocoder | ~> 1.8 | IPジオコーディング |
| browser | ~> 5.3 | User-Agent解析 |
| bootsnap | latest | 起動時間高速化 |
| tzinfo-data | latest | タイムゾーンデータ |

## bundle install 実行方法

```bash
# Docker環境内で実行
docker-compose run --rm web bundle install

# または、ローカル環境で実行
bundle install
```

## Gemfile.lock について
`bundle install`実行後、`Gemfile.lock`ファイルが生成されます。
このファイルは全ての依存関係の正確なバージョンを固定し、環境間での一貫性を保証します。

## 更新時の注意事項

1. **セキュリティアップデート**
   ```bash
   bundle update --conservative --group security
   ```

2. **特定Gemの更新**
   ```bash
   bundle update [gem名]
   ```

3. **メジャーバージョンアップ時**
   - CHANGELOG確認
   - 破壊的変更の影響調査
   - テスト環境での検証

## トラブルシューティング

### ネイティブ拡張のビルドエラー
```bash
# 必要なシステムパッケージをインストール
# PostgreSQL
sudo apt-get install libpq-dev

# ImageMagick
sudo apt-get install imagemagick libmagickwand-dev
```

### バージョン競合
```bash
# 依存関係をクリアして再インストール
rm Gemfile.lock
bundle install
```

## 関連ドキュメント
- [Rails 8.0.1 リリースノート](https://rubyonrails.org/2024/11/7/Rails-8-0-1-has-been-released)
- [仕様書](../specifications/spec.md)
- [環境構築手順](../README.md)