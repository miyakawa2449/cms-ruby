---
description: データベース状態・マイグレーション確認
---

データベースの状態を確認します。

## 実行内容
以下の情報を取得して報告してください：

1. **マイグレーション状態**
```bash
docker-compose exec web rails db:migrate:status
```

2. **テーブル一覧**
```bash
docker-compose exec web rails runner "puts ActiveRecord::Base.connection.tables.sort.join('\n')"
```

3. **各テーブルのレコード数**
```bash
docker-compose exec web rails runner "
  ActiveRecord::Base.connection.tables.each do |table|
    next if table == 'schema_migrations' || table == 'ar_internal_metadata'
    count = ActiveRecord::Base.connection.execute(\"SELECT COUNT(*) FROM #{table}\").first['count']
    puts \"#{table}: #{count}\"
  end
"
```

## オプション引数
- `$ARGUMENTS` が指定された場合、そのテーブルの詳細情報を表示

## 出力フォーマット
```markdown
## データベース状態

### マイグレーション
| Status | Migration ID | Migration Name |
|--------|--------------|----------------|

### テーブル統計
| テーブル名 | レコード数 |
|-----------|-----------|
```
