# Claude Code - 一般的な開発ガイドライン

## 📅 作成日: 2025-12-30
## 🎯 目的: Claude Codeが効率的に実装を進めるための指針

---

## 🏗️ プロジェクト技術スタック（必読）

### バックエンド
- **Ruby**: 3.4.7
- **Rails**: 8.1.1（最新版）
- **データベース**: PostgreSQL 16-alpine
- **認証**: Devise 4.9
- **バックグラウンド**: Sidekiq 8.0.10

### フロントエンド
- **CSS**: Tailwind CSS 3.0
- **JavaScript**: Stimulus + Turbo
- **バンドラー**: **esbuild**（重要！）
- **アセット**: Propshaft

### 開発環境
- **コンテナ**: Docker + docker-compose
- **Node.js**: package.jsonで管理
- **ビルドコマンド**: `npm run build`（esbuild実行）

---

## 🚨 重要な実装ルール

### Rule 1: JavaScriptライブラリの追加方法

#### ✅ 正しい方法（esbuildプロジェクト）

```bash
# 1. npmパッケージとして追加
docker-compose exec web npm install [package-name]

# 2. JavaScriptでimport
# app/javascript/controllers/xxx_controller.js
import Library from "package-name"

# 3. ビルド
docker-compose exec web npm run build

# 4. サーバー再起動
docker-compose restart web
```

#### ❌ 間違った方法（絶対にやらないこと）

```ruby
# config/importmap.rb にCDNを追加 ❌
pin "library", to: "https://cdn.jsdelivr.net/..."
```

```html
<!-- HTMLにCDNリンクを追加 ❌ -->
<script src="https://cdn.jsdelivr.net/..."></script>
```

**理由**: このプロジェクトはesbuildでバンドルしているため、CDNではなくnpmパッケージを使用する

---

### Rule 2: CSSライブラリの追加方法

#### ✅ 正しい方法

```bash
# 1. npmパッケージとして追加
docker-compose exec web npm install [package-name]

# 2. application.tailwind.cssにimport
# app/assets/stylesheets/application.tailwind.css
@import 'package-name/dist/style.css';

# 3. ビルド
docker-compose exec web npm run build
```

#### ❌ 間違った方法

```html
<!-- HTMLにCDNリンクを追加 ❌ -->
<link rel="stylesheet" href="https://cdn.jsdelivr.net/...">
```

---

### Rule 3: Stimulusコントローラーの作成

#### ✅ 正しい手順

```bash
# 1. コントローラーファイル作成
# app/javascript/controllers/xxx_controller.js

# 2. index.jsに登録
# app/javascript/controllers/index.js
import XxxController from "./xxx_controller"
application.register("xxx", XxxController)

# 3. ビルド
docker-compose exec web npm run build

# 4. HTMLでdata-controller属性を使用
<div data-controller="xxx">
  <button data-action="click->xxx#method">Click</button>
</div>
```

#### 🔍 デバッグ方法

```javascript
// コントローラーにログを追加
connect() {
  console.log('XxxController connected')
}

method() {
  console.log('method called')
}
```

ブラウザのConsole（F12）で確認:
- ページロード時: `XxxController connected`
- ボタンクリック時: `method called`

---

### Rule 4: ルーティングとヘルパー

#### Railsのルーティング確認

```bash
# ルート一覧を確認
docker-compose exec web rails routes | grep [keyword]

# 例: メディア関連のルート
docker-compose exec web rails routes | grep media
```

#### ヘルパー名の規則

```ruby
# config/routes.rb
resources :media, only: [:index, :show]

# 生成されるヘルパー
admin_media_path          # => /admin/media (index)
admin_medium_path(id)     # => /admin/media/:id (show)

# ❌ 間違い
admin_media_index_path    # => 存在しない！
```

**重要**: `resources`で生成されるヘルパーは`_index`が付かない

---

### Rule 5: データベース操作

#### マイグレーション実行

```bash
# コンテナ内で実行
docker-compose exec web rails db:migrate

# ステータス確認
docker-compose exec web rails db:migrate:status
```

#### モデルの動作確認

```bash
# Railsコンソール
docker-compose exec web rails console

# または rails runner
docker-compose exec web rails runner "puts User.count"
```

---

### Rule 6: エラーハンドリング

#### サーバーログの確認

```bash
# 最新50行を表示
docker-compose logs web --tail 50

# リアルタイムで監視
docker-compose logs web -f

# エラーのみ抽出
docker-compose logs web --tail 100 | grep -i "error\|exception"
```

#### よくあるエラーと対処法

**1. `undefined method 'xxx_path'`**
```bash
# ルートを確認
docker-compose exec web rails routes | grep xxx
```

**2. `ActiveRecord::ConnectionTimeoutError`**
```yaml
# config/database.yml
pool: 10  # プールサイズを増やす
checkout_timeout: 10
```

**3. `Content Security Policy violation`**
```ruby
# config/initializers/content_security_policy.rb
# 必要なドメインを追加
policy.script_src :self, "https://example.com"
```

---

## 📋 実装前のチェックリスト

新機能を実装する前に、必ず以下を確認してください：

### 1. 仕様書の確認
- [ ] `docs/specifications/features/` に該当する仕様書が存在するか
- [ ] 仕様書の要件をすべて理解したか
- [ ] 受け入れ基準を確認したか

### 2. 技術スタックの確認
- [ ] JavaScriptライブラリが必要な場合、npmで追加する方法を理解したか
- [ ] CSSライブラリが必要な場合、application.tailwind.cssに追加する方法を理解したか
- [ ] Stimulusコントローラーの作成方法を理解したか

### 3. 既存コードの確認
- [ ] 類似機能が既に実装されていないか確認したか
- [ ] 既存のサービスクラス・ヘルパーを再利用できないか確認したか
- [ ] 既存のStimulusコントローラーを参考にできないか確認したか

### 4. ルーティングの確認
- [ ] 必要なルートが定義されているか確認したか
- [ ] ヘルパー名を正しく理解したか（`_index`が付かないことを理解したか）

---

## 🔄 実装の標準フロー

### Phase 1: 設計・準備
1. 仕様書を読む
2. 必要なモデル・テーブルを確認
3. 必要なルートを確認
4. 必要なライブラリを確認

### Phase 2: バックエンド実装
1. マイグレーション作成・実行
2. モデル作成・バリデーション追加
3. コントローラー作成・アクション実装
4. サービスクラス作成（複雑なロジックの場合）
5. ルーティング追加

### Phase 3: フロントエンド実装
1. ビュー作成（ERB）
2. Stimulusコントローラー作成
3. JavaScriptライブラリ追加（必要な場合）
4. CSSスタイリング

### Phase 4: ビルド・テスト
1. `npm run build` 実行
2. `docker-compose restart web` 実行
3. ブラウザで動作確認
4. ブラウザConsoleでエラー確認
5. サーバーログでエラー確認

### Phase 5: デバッグ・修正
1. エラーメッセージを読む
2. ログを確認する
3. ルートを確認する
4. Stimulusコントローラーの接続を確認する
5. 修正後、Phase 4に戻る

---

## 🎯 品質基準

実装完了の定義：

### 機能要件
- [ ] 仕様書の全機能が実装されている
- [ ] 受け入れ基準をすべて満たしている
- [ ] エラーハンドリングが適切に実装されている

### 技術要件
- [ ] Railsの診断エラーがゼロ（`getDiagnostics`）
- [ ] ブラウザConsoleにエラーがない
- [ ] サーバーログにエラーがない
- [ ] レスポンシブデザインが適切に動作する

### コード品質
- [ ] コードが読みやすい（適切な命名・コメント）
- [ ] DRY原則に従っている（重複コードがない）
- [ ] セキュリティ対策が実装されている（CSRF、XSS等）
- [ ] パフォーマンスが考慮されている（N+1クエリ回避等）

---

## 📚 参考ドキュメント

### プロジェクト内ドキュメント
- **Phase計画書**: `docs/development/phase_plan_rails_8_1_1.md`
- **仕様書**: `docs/specifications/features/`
- **実装ログ**: `docs/development/implementation_log.md`
- **コーディング規約**: `docs/handoff/conventions.md`

### 外部ドキュメント
- **Rails Guides**: https://guides.rubyonrails.org/
- **Stimulus Handbook**: https://stimulus.hotwired.dev/handbook/introduction
- **Tailwind CSS**: https://tailwindcss.com/docs
- **esbuild**: https://esbuild.github.io/

---

## 🆘 困ったときの対処法

### 1. エラーメッセージを読む
- エラーメッセージには解決のヒントが含まれている
- ファイル名・行番号を確認する
- スタックトレースを確認する

### 2. ログを確認する
```bash
# サーバーログ
docker-compose logs web --tail 100

# ブラウザConsole
F12 → Console タブ
```

### 3. ルートを確認する
```bash
docker-compose exec web rails routes | grep [keyword]
```

### 4. 既存コードを参考にする
- 類似機能の実装を探す
- 同じパターンを使用する

### 5. 段階的にデバッグする
- console.logを追加する
- 一つずつ機能を確認する
- 動作する最小限のコードから始める

### 6. Kiroに相談する
- 問題の詳細を説明する
- エラーメッセージを共有する
- 試したことを報告する

---

## 🎓 学習リソース

### Rails 8.1の新機能
- Solid Queue（バックグラウンドジョブ）
- Solid Cache（キャッシュ）
- Solid Cable（WebSocket）

### Stimulus パターン
- Targets（DOM要素の参照）
- Values（データの保持）
- Actions（イベントハンドリング）
- Outlets（コントローラー間通信）

### Tailwind CSS
- ユーティリティファーストCSS
- レスポンシブデザイン（sm:, md:, lg:）
- ダークモード（dark:）

---

**作成者**: Kiro (AI Assistant)
**最終更新**: 2025-12-30
**対象**: Claude Code v2.0.72
