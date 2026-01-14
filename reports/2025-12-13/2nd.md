# Rails 8.1.1 + PostgreSQL 17-alpine 再実装計画書

**📅 作成日**: 2025年12月13日  
**🎯 目的**: 最新安定版への移行による長期運用基盤の確立  
**⚡ 対象**: Rails 8.0.4 → 8.1.1、PostgreSQL 16 → 17-alpine

---

## 🔍 背景と経緯

### 問題解決の経緯
1. **12月12日**: Web接続500エラー問題が発生
2. **本日午前**: Docker環境再起動により問題解決
3. **原因判明**: Railsバージョンの問題ではなく、Docker環境の状態問題

### 判明した事実
- 12月12日のレポートでRails 8.1.1 + PostgreSQL 17での動作実績確認
- その後Rails 8.0.4にダウングレードされていた
- 今回の問題解決により、バージョン問題ではないことが確定

---

## 🎯 移行の目的とメリット

### Rails 8.1.1 移行メリット
1. **最新機能**: 8.1系の新機能とパフォーマンス改善
2. **バグ修正**: 8.0.4以降の重要なバグ修正を含む
3. **長期サポート**: より新しいバージョンでの運用

### PostgreSQL 17 移行メリット
1. **EOL延長**: 2029年11月まで（5年間）のサポート
2. **パフォーマンス**: 最新の最適化とインデックス改善
3. **機能拡張**: JSONBパフォーマンス向上など

---

## 📋 再実装計画

### Phase 1: 準備作業（30分）

#### 1.1 現在環境のバックアップ
```bash
# Gemfile.lockのバックアップ
cp Gemfile.lock Gemfile.lock.8.0.4.backup

# database.ymlのバックアップ
cp config/database.yml config/database.yml.backup

# docker-compose.ymlのバックアップ
cp docker-compose.yml docker-compose.yml.backup

# 現在のGemリスト保存
docker-compose run --rm web bundle list > gem_list_8.0.4.txt
```

#### 1.2 データのバックアップ
```bash
# データベースダンプ作成
docker-compose exec db pg_dump -U portfolio portfolio_rb_development > backup_before_upgrade.sql

# 現在のテストデータも保存
docker-compose run --rm web rails runner "
  puts 'Backing up test data...'
  File.open('test_data_backup.rb', 'w') do |f|
    f.puts TestItem.all.to_json
  end
"
```

### Phase 2: Rails 8.1.1 アップグレード（45分）

#### 2.1 Gemfile更新
```ruby
# Gemfile
gem "rails", "~> 8.1.1"
```

#### 2.2 Bundle更新
```bash
# ローカルで bundle update
bundle update rails

# 依存関係の確認
bundle exec rails app:update
```

#### 2.3 設定ファイルの確認
- 新しい設定項目の確認
- deprecation warningの確認
- config/application.rbの更新

### Phase 3: PostgreSQL 17 移行（30分）

#### 3.1 docker-compose.yml更新
```yaml
services:
  db:
    image: postgres:17-alpine  # 16から17へ
    environment:
      POSTGRES_DB: portfolio_rb_development
      POSTGRES_USER: portfolio
      POSTGRES_PASSWORD: portfolio_password
      POSTGRES_INITDB_ARGS: "--encoding=UTF-8 --locale-provider=icu --icu-locale=ja-JP"
```

#### 3.2 環境再構築
```bash
# 完全クリーンアップ
docker-compose down -v

# イメージの再ビルド
docker-compose build --no-cache

# 環境起動
docker-compose up -d
```

### Phase 4: データ移行と検証（45分）

#### 4.1 データベース作成
```bash
# データベース作成とマイグレーション
docker-compose exec web rails db:create
docker-compose exec web rails db:migrate
```

#### 4.2 シードデータ投入
```bash
# 既存シードデータの実行
docker-compose exec web rails db:seed

# テストデータの復元
docker-compose run --rm web rails runner db/seeds/create_test_data.rb
```

#### 4.3 動作確認テスト
```bash
# 基本的な接続テスト
curl http://localhost:3000/test

# 各エンドポイントの確認
curl -I http://localhost:3000/
curl -I http://localhost:3000/admin
curl -I http://localhost:3000/api/v1/
curl -I http://localhost:3000/blog
```

### Phase 5: 統合テスト（30分）

#### 5.1 機能別テスト
- [ ] ポートフォリオトップページ
- [ ] 管理画面ログイン
- [ ] 記事一覧・詳細表示
- [ ] セクション管理
- [ ] API応答確認

#### 5.2 パフォーマンステスト
```bash
# レスポンスタイム測定
time curl http://localhost:3000/
time curl http://localhost:3000/api/v1/articles
```

---

## 🚨 リスクと対策

### 想定されるリスク
1. **gem互換性問題**
   - 対策: 事前にGemfile.lockバックアップ、問題時は即座にロールバック

2. **データベース互換性**
   - 対策: PostgreSQL 16→17は上位互換、ダンプ・リストアで対応

3. **設定ファイル変更**
   - 対策: rails app:updateで差分確認、慎重にマージ

### ロールバック計画
```bash
# Railsのロールバック
cp Gemfile.lock.8.0.4.backup Gemfile.lock
bundle install

# PostgreSQLのロールバック
# docker-compose.ymlを元に戻してから
docker-compose down -v
docker-compose up -d
docker-compose exec web rails db:create db:migrate
docker-compose exec db psql -U portfolio portfolio_rb_development < backup_before_upgrade.sql
```

---

## 📊 成功基準

### 必須要件
- ✅ 全エンドポイントが200/302で応答
- ✅ 管理画面へのログインが可能
- ✅ データベース接続エラーなし
- ✅ 既存データの完全性維持

### 性能要件
- レスポンスタイムの劣化なし
- メモリ使用量の異常増加なし
- CPU使用率の異常なし

---

## 📅 実施スケジュール

### 推定所要時間: 3時間

1. **13:30-14:00**: Phase 1 準備作業
2. **14:00-14:45**: Phase 2 Rails アップグレード
3. **14:45-15:15**: Phase 3 PostgreSQL 移行
4. **15:15-16:00**: Phase 4 データ移行
5. **16:00-16:30**: Phase 5 統合テスト

### チェックポイント
- Phase 2完了後: Rails単体での動作確認
- Phase 3完了後: DB接続の基本確認
- Phase 4完了後: 全データの整合性確認

---

## 🎯 期待される成果

### 技術的成果
1. **最新安定版での運用**: セキュリティとパフォーマンスの向上
2. **長期サポート**: 2029年までの安定運用基盤
3. **新機能活用**: Rails 8.1.1の新機能を活用可能

### プロジェクト成果
1. **MVP品質向上**: 最新技術スタックでの提供
2. **保守性向上**: より長いサポート期間
3. **将来性確保**: アップグレードパスの確立

---

**実施判断**: 本日の問題解決により、バージョン問題ではないことが判明。
週末を利用した移行実施により、来週からの安定運用を目指す。