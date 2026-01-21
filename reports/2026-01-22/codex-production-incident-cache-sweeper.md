# 本番障害レポート - CacheSweeper delete_matched（SolidCache）

作成日: 2026-01-22
作成者: Codex

## 概要
本番環境で保存系の操作（記事の作成/更新、カテゴリ更新）がすべて 500 になる障害が発生しました。原因は `CacheSweeper#clear_cache_matched` が `SolidCache::Store` の `delete_matched` により `NotImplementedError` を投げることでした。`NotImplementedError` を握りつぶすガードを追加し、デプロイ後に正常に保存できることを確認しました。

## 影響範囲
- 管理画面の保存系が 500
  - 記事の新規作成/更新
  - カテゴリの更新
- 一覧・閲覧などの読み取り系は正常

## 原因
`CacheSweeper#clear_cache_matched` は `Rails.cache.respond_to?(:delete_matched)` の真偽で分岐していましたが、SolidCache はメソッド自体は実装されており、実行時に `NotImplementedError` を投げる挙動でした。この例外が after_commit で伝播し、保存処理が 500 で失敗していました。

## 証跡（本番ログ）
- 例外: `NotImplementedError (SolidCache::Store does not support delete_matched)`
- スタック:
  - `app/models/concerns/cache_sweeper.rb:43`
  - `app/models/article.rb:158` / `app/models/category.rb:53`
  - `Admin::ArticlesController#update` / `Admin::CategoriesController#update`

## 対応内容
`CacheSweeper#clear_cache_matched` に `NotImplementedError` の rescue を追加し、例外を握りつぶして警告ログを出すようにしました。

変更ファイル:
- `app/models/concerns/cache_sweeper.rb`

コミット:
- `29ff30a` "Guard cache delete_matched for SolidCache"

## デプロイ
- main に push
- Lightsail（Docker）へデプロイ

## 検証結果
- 本番で記事保存/カテゴリ更新が正常に完了することを確認

## 今後の検討事項
1. 本番の cache store を `delete_matched` 対応ストア（例: Redis）へ切替するか、SolidCache 前提で運用するか判断
2. 起動時に delete_matched 非対応の警告を出す仕組みの追加
3. `clear_cache_matched` が例外を投げないことを担保する回帰テストの追加
