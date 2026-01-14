---
description: Railsコンソールでデバッグ・データ確認
---

Railsコンソールを使用してデータ確認やデバッグを行います。

## 使用方法
引数に実行したいRubyコードを指定してください。

## 実行内容
1. Docker環境でRailsコンソールを起動
2. 指定されたコードを実行
3. 結果を表示

## コマンド
```bash
docker-compose exec web rails runner "$ARGUMENTS"
```

## よく使うクエリ例
- `Article.count` - 記事数確認
- `AdminUser.all` - 管理者一覧
- `Category.pluck(:name)` - カテゴリ名一覧
- `Article.published.last(5)` - 最新公開記事5件

## 注意
- 本番環境では使用しないでください
- データ変更系のコマンドは慎重に実行してください
