# AWS S3 バックアップガイド

## 📅 作成日: 2026-01-22
## 🎯 対象: Portfolio Site バックアップシステム（Phase 7実装用）

---

## 📋 目次

1. [AWS S3とは](#aws-s3とは)
2. [コスト試算](#コスト試算)
3. [セキュリティ](#セキュリティ)
4. [推奨設定](#推奨設定)
5. [実装手順](#実装手順)
6. [運用ガイド](#運用ガイド)
7. [トラブルシューティング](#トラブルシューティング)

---

## 🌐 AWS S3とは

### 概要
**Amazon S3（Simple Storage Service）**は、AWSが提供するオブジェクトストレージサービスです。

### 特徴
- **マネージドサービス**: OS管理・セキュリティ更新が不要
- **高耐久性**: 99.999999999%（イレブンナイン）のデータ耐久性
- **スケーラブル**: 容量無制限、必要な分だけ使用
- **低コスト**: 使った分だけの従量課金
- **高セキュリティ**: 暗号化、アクセス制御が標準装備

### 従来のバックアップサーバーとの違い

| 項目 | バックアップサーバー | AWS S3 |
|------|-------------------|--------|
| **OS管理** | 必要（パッチ適用、セキュリティ更新） | **不要（AWS側で自動管理）** |
| **初期費用** | サーバー購入費（数万円〜） | **無料** |
| **月額費用** | $10-50/月 | **$1-5/月** |
| **セキュリティ更新** | 手動で実施 | **自動** |
| **冗長化** | 自分で設定（RAID等） | **自動（複数データセンター）** |
| **容量制限** | ディスク容量に依存 | **無制限** |
| **スケーラビリティ** | ハードウェア増設が必要 | **自動拡張** |
| **災害対策** | 別拠点にバックアップが必要 | **複数リージョンに自動分散** |

---

## 💰 コスト試算

### 想定データ量（Portfolio Site）
- **データベース（PostgreSQL）**: 50MB（圧縮後）
- **Active Storage（画像）**: 2GB
- **設定ファイル**: 1MB
- **合計**: 約2GB

### 世代管理による保存量
- **日次バックアップ**: 2GB × 7日 = 14GB
- **週次バックアップ**: 2GB × 4週 = 8GB
- **月次バックアップ**: 2GB × 12ヶ月 = 24GB
- **合計保存量**: 約46GB

### S3料金（東京リージョン - ap-northeast-1）

#### 1. ストレージ料金

**S3 Standard**（頻繁にアクセスするデータ用）
- 料金: $0.025/GB/月
- 用途: 日次バックアップ（7日分）
- コスト: 14GB × $0.025 = **$0.35/月（約53円）**

**S3 Glacier Instant Retrieval**（長期保存用）
- 料金: $0.005/GB/月
- 用途: 週次・月次バックアップ
- コスト: 32GB × $0.005 = **$0.16/月（約24円）**
- 特徴: 即座に取り出し可能、コストは1/5

#### 2. リクエスト料金
- **PUT/COPY**: $0.0047/1,000リクエスト
- **GET**: $0.00037/1,000リクエスト
- 日次バックアップ: 30回/月 → **約$0.01/月（約1.5円）**

#### 3. データ転送料金
- **アップロード（インターネット → S3）**: **無料**
- **ダウンロード（S3 → インターネット）**: 最初の100GB/月は**無料**
- 復元時のみ課金（通常は無料範囲内）

### 月額コスト合計

```
ストレージ料金: $0.51/月（約77円）
リクエスト料金: $0.01/月（約1.5円）
データ転送料金: $0/月（無料範囲内）

合計: 約$0.52/月（約78円）
年間: 約$6.24/年（約936円）
```

### データ量別コスト試算

| データ量 | 日次(7日) | 週次(4週) | 月次(12ヶ月) | 合計保存量 | 月額コスト |
|---------|----------|----------|------------|-----------|----------|
| 2GB | 14GB | 8GB | 24GB | 46GB | **約78円** |
| 5GB | 35GB | 20GB | 60GB | 115GB | 約200円 |
| 10GB | 70GB | 40GB | 120GB | 230GB | 約400円 |
| 20GB | 140GB | 80GB | 240GB | 460GB | 約800円 |
| 50GB | 350GB | 200GB | 600GB | 1,150GB | 約2,000円 |

---

## 🔒 セキュリティ

### S3のセキュリティ機能（OS管理不要）

#### 1. サーバーサイド暗号化（SSE）

**SSE-S3（推奨）**
- AES-256暗号化
- AWS側で鍵管理
- 追加料金なし
- 設定: ワンクリック

```ruby
# Rails実装例
s3_client.put_object(
  bucket: 'portfolio-backup-miyakawa2449',
  key: 'backup-20260122.zip',
  body: file,
  server_side_encryption: 'AES256'  # ← これだけで暗号化
)
```

**SSE-KMS（高度なセキュリティが必要な場合）**
- AWS KMS（Key Management Service）で鍵管理
- 鍵のローテーション、監査ログ
- 追加料金: $1/月 + リクエスト料金

#### 2. アクセス制御

**IAMポリシー（推奨）**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:DeleteObject"
      ],
      "Resource": [
        "arn:aws:s3:::portfolio-backup-miyakawa2449",
        "arn:aws:s3:::portfolio-backup-miyakawa2449/*"
      ]
    }
  ]
}
```

**バケットポリシー（パブリックアクセスブロック）**
```json
{
  "BlockPublicAcls": true,
  "IgnorePublicAcls": true,
  "BlockPublicPolicy": true,
  "RestrictPublicBuckets": true
}
```
- デフォルトで有効（推奨）
- 誤ってパブリック公開するリスクを防止

#### 3. バージョニング（誤削除対策）
- 有効化するだけで自動バージョン管理
- 誤削除しても復元可能
- 追加料金: 保存容量分のみ

#### 4. MFA Delete（高度なセキュリティ）
- オブジェクト削除時にMFA（多要素認証）を要求
- 誤削除・不正削除を防止
- 本番環境で推奨

#### 5. アクセスログ
- すべてのアクセスをログ記録
- 不正アクセスの検知
- 監査証跡として利用

---

## 🎯 推奨設定

### 1. S3バケット作成

**基本設定**
```
バケット名: portfolio-backup-miyakawa2449
リージョン: ap-northeast-1（東京）
パブリックアクセス: すべてブロック
バージョニング: 有効
暗号化: SSE-S3（AES-256）
オブジェクトロック: 無効（通常は不要）
```

### 2. ライフサイクルポリシー

**日次バックアップ**
```
保存期間: 7日間
ストレージクラス: S3 Standard
7日後: Glacier Instant Retrieval に移行
30日後: 削除
```

**週次バックアップ**
```
保存期間: 4週間
ストレージクラス: Glacier Instant Retrieval（即座に移行）
90日後: 削除
```

**月次バックアップ**
```
保存期間: 12ヶ月
ストレージクラス: Glacier Instant Retrieval（即座に移行）
365日後: 削除
```

### 3. IAMロール（Lightsail/EC2用）

**ロール名**: `PortfolioBackupRole`

**ポリシー**:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "BackupOperations",
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:DeleteObject"
      ],
      "Resource": [
        "arn:aws:s3:::portfolio-backup-miyakawa2449",
        "arn:aws:s3:::portfolio-backup-miyakawa2449/*"
      ]
    }
  ]
}
```

### 4. バケットタグ

```
Environment: production
Project: portfolio-site
Purpose: backup
Owner: miyakawa2449
```

---

## 🛠 実装手順

### Phase 1: AWS S3バケット作成（手動）

#### 1. AWSマネジメントコンソールにログイン
```
https://console.aws.amazon.com/
```

#### 2. S3サービスに移動
- サービス → ストレージ → S3

#### 3. バケット作成
1. 「バケットを作成」ボタンをクリック
2. バケット名: `portfolio-backup-miyakawa2449`
3. リージョン: `アジアパシフィック（東京）ap-northeast-1`
4. 「パブリックアクセスをすべてブロック」: ✅ チェック
5. 「バケットのバージョニング」: ✅ 有効化
6. 「デフォルトの暗号化」: ✅ 有効化（SSE-S3）
7. 「バケットを作成」ボタンをクリック

#### 4. ライフサイクルルール設定
1. 作成したバケットをクリック
2. 「管理」タブ → 「ライフサイクルルールを作成」
3. ルール名: `daily-backup-lifecycle`
4. ルールスコープ: `プレフィックスを指定` → `daily/`
5. ライフサイクルルールアクション:
   - ✅ オブジェクトの現行バージョンを移行
   - ✅ オブジェクトの現行バージョンを完全に削除
6. 移行設定:
   - 7日後 → Glacier Instant Retrieval
   - 30日後 → 削除
7. 「ルールを作成」ボタンをクリック

同様に `weekly/` と `monthly/` のルールも作成

### Phase 2: IAMロール作成（手動）

#### 1. IAMサービスに移動
- サービス → セキュリティ、ID、およびコンプライアンス → IAM

#### 2. ロール作成
1. 「ロール」→「ロールを作成」
2. 信頼されたエンティティタイプ: `AWSのサービス`
3. ユースケース: `EC2`
4. 「次へ」ボタンをクリック

#### 3. ポリシー作成
1. 「ポリシーを作成」ボタンをクリック
2. JSON タブをクリック
3. 上記のIAMポリシーJSONを貼り付け
4. ポリシー名: `PortfolioBackupPolicy`
5. 「ポリシーを作成」ボタンをクリック

#### 4. ロールにポリシーをアタッチ
1. 作成したポリシーを検索・選択
2. 「次へ」ボタンをクリック
3. ロール名: `PortfolioBackupRole`
4. 「ロールを作成」ボタンをクリック

#### 5. Lightsailインスタンスにロールをアタッチ
1. Lightsailコンソールに移動
2. インスタンスをクリック
3. 「ネットワーキング」タブ → 「IAMロール」
4. 作成したロールを選択

### Phase 3: Rails実装（Phase 7で実施）

#### 1. Gemfile追加
```ruby
gem 'aws-sdk-s3', '~> 1.0'
```

#### 2. 環境変数設定
```bash
# .env
AWS_REGION=ap-northeast-1
S3_BACKUP_BUCKET=portfolio-backup-miyakawa2449
```

#### 3. バックアップサービス実装
```ruby
# app/services/backup/s3_uploader.rb
module Backup
  class S3Uploader
    def initialize
      @s3_client = Aws::S3::Client.new(region: ENV['AWS_REGION'])
      @bucket = ENV['S3_BACKUP_BUCKET']
    end

    def upload(file_path, backup_type)
      key = generate_key(backup_type)
      
      File.open(file_path, 'rb') do |file|
        @s3_client.put_object(
          bucket: @bucket,
          key: key,
          body: file,
          server_side_encryption: 'AES256'
        )
      end
      
      Rails.logger.info "Backup uploaded: #{key}"
      key
    end

    private

    def generate_key(backup_type)
      timestamp = Time.current.strftime('%Y%m%d_%H%M%S')
      "#{backup_type}/backup_#{timestamp}.zip"
    end
  end
end
```

---

## 📖 運用ガイド

### 日常運用

#### 1. バックアップ確認
- 管理画面のバックアップダッシュボードで確認
- 日次: 毎日午前3時に自動実行
- 週次: 毎週日曜日に自動実行
- 月次: 毎月1日に自動実行

#### 2. バックアップ失敗時の対応
1. メール通知を確認
2. ログを確認（`log/production.log`）
3. 手動バックアップを実行
4. 原因調査・修正

#### 3. 復元手順
1. 管理画面のバックアップ一覧から復元ポイントを選択
2. 「復元」ボタンをクリック
3. 確認ダイアログで「OK」
4. 復元完了を待つ（数分〜数十分）
5. アプリケーション再起動

### 月次運用

#### 1. ストレージ容量確認
- S3コンソールで使用量を確認
- 予想外の増加がないかチェック

#### 2. コスト確認
- AWS Billing Dashboardで料金を確認
- 予算アラート設定（$10/月等）

#### 3. バックアップ整合性チェック
- ランダムに1つのバックアップを復元テスト
- データベース接続確認
- 画像表示確認

---

## 🔧 トラブルシューティング

### 問題1: バックアップアップロードが失敗する

**症状**:
```
Aws::S3::Errors::AccessDenied: Access Denied
```

**原因**:
- IAMロールの権限不足
- バケット名の誤り

**解決方法**:
1. IAMロールのポリシーを確認
2. バケット名が正しいか確認（`.env`）
3. Lightsailインスタンスにロールがアタッチされているか確認

### 問題2: バックアップダウンロードが遅い

**症状**:
- 復元に時間がかかる

**原因**:
- Glacier Instant Retrievalからの取得

**解決方法**:
- 日次バックアップ（S3 Standard）から復元
- 事前に取得リクエストを送信

### 問題3: ストレージ容量が予想以上に増加

**症状**:
- 月額コストが予想より高い

**原因**:
- バージョニングによる古いバージョンの蓄積
- ライフサイクルポリシーの未設定

**解決方法**:
1. バージョニングの古いバージョンを削除
2. ライフサイクルポリシーを確認・修正
3. 不要なバックアップを手動削除

### 問題4: 暗号化されていない

**症状**:
- S3コンソールで暗号化が「なし」と表示

**原因**:
- アップロード時に暗号化オプションを指定していない

**解決方法**:
```ruby
# server_side_encryption オプションを追加
@s3_client.put_object(
  bucket: @bucket,
  key: key,
  body: file,
  server_side_encryption: 'AES256'  # ← 必須
)
```

---

## 📚 参考リンク

### AWS公式ドキュメント
- [Amazon S3 とは](https://docs.aws.amazon.com/ja_jp/AmazonS3/latest/userguide/Welcome.html)
- [S3 料金](https://aws.amazon.com/jp/s3/pricing/)
- [S3 セキュリティベストプラクティス](https://docs.aws.amazon.com/ja_jp/AmazonS3/latest/userguide/security-best-practices.html)
- [S3 ライフサイクル管理](https://docs.aws.amazon.com/ja_jp/AmazonS3/latest/userguide/object-lifecycle-mgmt.html)

### AWS SDK for Ruby
- [AWS SDK for Ruby - S3](https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/S3.html)
- [aws-sdk-s3 gem](https://rubygems.org/gems/aws-sdk-s3)

### コスト計算ツール
- [AWS 料金計算ツール](https://calculator.aws/)
- [S3 コスト最適化ガイド](https://aws.amazon.com/jp/s3/cost-optimization/)

---

## ✅ チェックリスト

### 初期設定
- [ ] S3バケット作成
- [ ] パブリックアクセスブロック有効化
- [ ] バージョニング有効化
- [ ] 暗号化有効化（SSE-S3）
- [ ] ライフサイクルポリシー設定
- [ ] IAMロール作成
- [ ] Lightsailインスタンスにロールアタッチ
- [ ] 環境変数設定（`.env`）
- [ ] 初回バックアップテスト
- [ ] 復元テスト

### 月次確認
- [ ] ストレージ容量確認
- [ ] コスト確認
- [ ] バックアップ整合性チェック
- [ ] ライフサイクルポリシー動作確認

---

**📝 作成者**: Kiro（仕様管理担当）  
**📅 作成日**: 2026-01-22  
**🔄 バージョン**: v1.0  
**📋 関連Phase**: Phase 7（セキュリティ・運用強化）
