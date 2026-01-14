# 12月17-18日 開発作業詳細分析
作成日: 2025-12-19
分析対象: 12月17日（13件）+ 12月18日（7件 + ブログ草案3件）
主要テーマ: 本番環境安定化・メール機能実装・セキュリティ強化・MVP仕上げ

---

# 第1部：12月17日の分析

## 概要

12月17日は、本番環境の安定化とユーザー向け機能の完成に集中した一日だった。Docker環境でのActive Storage問題解決から始まり、AWS SESによるメール送信機能の完全実装、そしてMy Story機能の複数の問題修正まで、幅広い作業を完了させた。

## 実装トピック一覧（17日）

### 1. インフラ・環境関連

#### 1.1 Active Storage URL修正
- **課題**: Docker環境でFavicon・Logo画像が表示されない
- **原因**: Active StorageがDocker内部ホスト名を使用してURL生成
- **解決策**:
  - プロキシモード設定（`rails_storage_proxy`）
  - Nginxのホスト名固定化（`$http_host` → `miyakawa.codes`）
  - ミドルウェアによる明示的URL設定

```ruby
# Active Storage proxy mode configuration
config.active_storage.resolve_model_to_route = :rails_storage_proxy
```

#### 1.2 deploy.sh安全性強化
- **課題**: 本番デプロイの安全性・運用性向上
- **実装内容**:
  - 包括的エラーハンドリング（`trap`によるエラー検知）
  - 高度オプション追加（`--keep-ssl`, `--recreate`, `--reset-admin`）
  - 環境変数バリデーション
  - 段階的起動確認

**変更規模**: 189行削除 → 621行（約3倍に拡張）

#### 1.3 ロゴ表示修正
- **課題**: `NoMethodError: undefined method 'polymorphic_url'`
- **原因**: Service層でのRails URL helper不足
- **解決策**: 明示的にURL helperを呼び出し

```ruby
# Before
polymorphic_url(logo_setting.image_value)

# After
Rails.application.routes.url_helpers.rails_storage_proxy_path(
  logo_setting.image_value,
  only_path: true
)
```

### 2. メール機能（AWS SES）

#### 2.1 お問い合わせ機能・AWS SES実装
- 管理画面メニュー追加
- AWS SES SDK設定
- ContactMailer作成（HTML/テキスト対応）
- UX改善・送信完了フィードバック

**変更規模**: 18ファイル, 838行追加

#### 2.2 方式選択の変遷

| 時点 | 方式 | 理由 |
|------|------|------|
| 初期実装 | SDK v1形式 | 公式ドキュメント参照 |
| LoadError発生 | SMTP | 緊急対応・信頼性優先 |
| 最終決定 | SES v2 API | ユーザー指示・機能優先 |

```ruby
# 最終形: SES v2 API configuration
config.action_mailer.delivery_method = :sesv2
config.action_mailer.sesv2_settings = {
  region: ENV['AWS_DEFAULT_REGION'],
  access_key_id: ENV['AWS_ACCESS_KEY_ID'],
  secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
}
```

### 3. UI/UX改善

#### 3.1 Stimulusコントローラー登録
- **課題**: お問い合わせフォーム送信後のUI反応なし
- **原因**: ContactFormControllerがStimulusに未登録
- **解決策**: index.jsでの明示的登録、10秒後フェードアウト実装

### 4. My Story機能改善

#### 4.1 修正項目一覧
1. 章フィールド保存機能実装（仮想属性パターン）
2. 500エラー修正（section_type nilチェック追加）
3. フォームStimulus化（90行のインラインJS削除）
4. タイムライン年数表記修正（16年→20年、2021→2025）
5. セクション削除403エラー修正（button_to + turbo_confirm）
6. Rakeタスク包括的改良（セクション自動作成）

#### 4.2 Rails 7 + Turbo対応

```erb
<!-- Before（Rails 6以前） -->
<%= link_to "削除", path, method: :delete, confirm: "本当に？" %>

<!-- After（Rails 7 + Turbo） -->
<%= button_to "削除", path, method: :delete,
    data: { turbo_confirm: "本当に？" },
    form: { class: "inline" } %>
```

## 17日の変更統計

| カテゴリ | ファイル数 | 追加行 | 削除行 |
|----------|-----------|--------|--------|
| インフラ | 10+ | 500+ | 200+ |
| メール機能 | 20+ | 900+ | 100+ |
| UI/UX | 10+ | 100+ | 30+ |
| My Story | 15+ | 300+ | 100+ |
| **合計** | **55+** | **1800+** | **430+** |

---

# 第2部：12月18日の分析

## 概要

12月18日は、MVP完成に向けた最終段階の作業日だった。Google Tag Manager実装、CSP設定の大幅見直し、そしてセキュリティ強化（Devise認証・Contact暗号化）を完了。さらに、この開発体験をブログ記事として発信するための草案も作成された。

## 実装トピック一覧（18日）

### 1. 分析ツール統合

#### 1.1 Google Tag Manager実装
- `SiteSettingTypeManager`に`gtm_id`設定追加
- 管理画面でのGTM ID入力フィールド
- GTMヘルパー作成（`gtm_helper.rb`）
- 条件付きタグ出力（空欄時は出力なし）

```ruby
def gtm_installed?
  @gtm_id ||= SiteSetting.find_by(key: 'gtm_id')&.value
  @gtm_id.present?
end
```

### 2. CSP（Content Security Policy）設定

#### 2.1 CSP設定の二重修正
- **1回目**: `config/initializers/content_security_policy.rb`を修正（効果なし）
- **2回目**: 実際の設定場所`application_controller.rb`を発見・修正

| ディレクティブ | 修正前 | 修正後 |
|--------------|-------|--------|
| script-src | cdn.jsdelivr.netのみ | +GTM/GA4/Clarity全ドメイン |
| connect-src | api.openai.com | GA4/Clarity関連に置換 |
| frame-src | なし | GTMプレビュー用に追加 |
| worker-src | なし | Clarity用（blob:）に追加 |

### 3. セキュリティ強化

#### 3.1 Devise認証強化
- **Registerable削除**: 不正管理者登録防止
- **Lockable追加**: 5回失敗で1時間ロック
- **Timeoutable追加**: 30分無操作でセッション切れ

```ruby
devise :database_authenticatable, :recoverable,
       :rememberable, :validatable, :lockable, :timeoutable
```

#### 3.2 Contact暗号化
- **Active Record Encryption**適用
- email: deterministic（検索可能）
- name, message: non-deterministic（より安全）
- Honeypotフィールド追加（ボット対策）

#### 3.3 既存データ互換性
- **課題**: 既存平文データで500エラー
- **解決**: `support_unencrypted_data = true`

```ruby
Rails.application.config.active_record.encryption.support_unencrypted_data = true
```

### 4. UI/命名統一

#### 4.1 Services表記統一
- DBセクション名: `service` → `services`
- アンカーリンク更新（4箇所）
- パーシャルファイル名変更

#### 4.2 Twitter Card/OGPメタタグ改善
- `twitter:site`を正しいハンドル（`@miyakawa2449`）に修正
- 画像サイズメタタグ追加（1200x628）

### 5. ブログ記事準備

- ブログ草案作成（約3000文字構成）
- エッセンス集作成（数字・フレーズ・エピソード）
- 対話例集作成（8つの協働パターン）

## 18日の変更統計

| カテゴリ | ファイル数 | 主な変更 |
|----------|-----------|----------|
| 分析ツール | 6 | GTM設定機能 |
| CSP設定 | 2 | GTM/GA4/Clarity許可 |
| セキュリティ | 10 | Devise強化、暗号化 |
| UI統一 | 6 | Services表記、OGP |
| ブログ草案 | 3 | 記事構成・素材 |
| **合計** | **27+** | - |

---

# 第3部：技術的判断と教訓

## 問題解決パターン

### パターン1: 環境差異への対応
- **事例**: Docker内部ホスト名問題
- **アプローチ**: 明示的な設定で環境差異を吸収
- **ツール**: ミドルウェア、環境変数

### パターン2: 緊急対応と最適化の分離
- **事例**: AWS SES LoadError
- **アプローチ**: まず動かす（SMTP）→ 最適化（API）
- **判断基準**: ビジネス継続性 > 技術的完璧さ

### パターン3: 設定場所の特定
- **事例**: CSPがinitializerではなくcontrollerで設定
- **アプローチ**: grepで実際の設定場所を特定
- **教訓**: フレームワーク標準と実装が異なる場合がある

### パターン4: 下位互換性の確保
- **事例**: 既存平文データのContact
- **アプローチ**: `support_unencrypted_data`で段階移行
- **教訓**: 本番データを壊さない配慮が重要

### パターン5: フレームワーク移行対応
- **事例**: Rails 7 + Turboでの削除エラー
- **アプローチ**: 新しい標準パターンへの移行
- **ポイント**: `button_to` + `turbo_confirm`

## 教訓・学習ポイント

### 技術面
1. **Active Storage in Docker**: プロキシモード + 明示的ホスト設定が必須
2. **AWS SES**: aws-sdk-railsが最適な統合方法
3. **Rails 7 Turbo**: 既存パターンの見直しが必要
4. **Stimulus**: 明示的登録を忘れずに
5. **CSP設定**: 複数サービス許可時はディレクティブごとに整理
6. **Active Record Encryption**: deterministic vs non-deterministic の使い分け

### プロセス面
1. **段階的デプロイ**: リスク軽減の基本
2. **冪等性確保**: Rakeタスクは複数回実行可能に
3. **設定場所の確認**: 想定と実際が異なる可能性を意識
4. **ドキュメント発信**: 開発と並行して知見を記事化する価値

---

# 第4部：総括

## 2日間の実績

| 項目 | 17日 | 18日 | 合計 |
|------|------|------|------|
| コミット数 | 13回 | 7回+ | 20回+ |
| 変更ファイル | 55+ | 27+ | 82+ |
| 追加行数 | 1,800+ | 500+ | 2,300+ |
| 解決した問題 | 10+ | 8+ | 18+ |

## 次期課題への申し送り

### 完了事項
- [x] Docker環境Active Storage問題解決
- [x] AWS SES v2 API実装完了
- [x] My Story機能の主要問題解決
- [x] Google Tag Manager設定機能
- [x] CSP設定（GTM/GA4/Clarity対応）
- [x] Deviseセキュリティ強化
- [x] Contact暗号化・スパム対策
- [x] Services表記統一
- [x] Twitter Card/OGPメタタグ改善

### 継続課題
- [ ] 404/500エラーページカスタマイズ
- [ ] AWS SES送信制限・レート管理
- [ ] CloudWatchメトリクス設定
- [ ] twitter:siteの管理画面設定化
- [ ] pg_search導入（Phase 5）

### 本番デプロイ時の注意
```bash
# 1. Services表記統一
Section.find_by(name: "service")&.update(name: "services")

# 2. Twitter Card確認
https://cards-dev.twitter.com/validator

# 3. セキュリティ動作確認
# - ログイン5回失敗でロック
# - 30分無操作でセッション切れ
```

---

**作成者**: Claude Code
**分析対象**: 17日13件 + 18日7件（技術）+ 3件（ブログ草案）= 計23件
