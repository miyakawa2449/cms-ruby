# 包括的リファクタリング計画書 - 2025-12-13

## 📋 計画概要

### 実施理由
1. **技術基盤刷新後**: Rails 8.1.1・PostgreSQL 17・新依存関係導入完了
2. **主要機能完成**: OGP・認証・CMS・API基盤が動作確認済み
3. **技術的負債蓄積**: Phase 2-3での機能追加による複雑化
4. **MVP前の最適タイミング**: 安定期間での品質向上

### 実施方針
- **段階的実行**: 一度に全てを変更せず、段階的にリスク管理
- **動作確認重視**: 各段階で全機能の動作確認
- **コミット細分化**: 問題発生時の切り戻しを容易にする
- **ドキュメント更新**: 変更内容の記録と今後の参考資料作成

---

## 🎯 コード分析結果

### 現在の問題点

#### Fat Model (264行)
- `MyStorySection`: JSONB操作・バリデーション・ビジネスロジック混在
- `Article` (108行): 検索・公開管理・関連記事取得など多責務
- `SiteSetting` (90行): 設定管理・キャッシュ・メタプログラミング混在

#### Fat Controller
- `Admin::MyStorySectionsController` (166行): CRUD・位置変更・状態管理
- `Admin::SectionContentsController` (103行): セクションコンテンツ・アクティベーション
- `Admin::ArticlesController` (94行): 記事管理・公開制御・関連データ処理

#### Helper/Service肥大化
- `ApplicationHelper` (99行): 複数責務混在
- `MetaTagsService` (239行): 最近リファクタリング済み（良好）
- `SiteAssetsService` (134行): 最近リファクタリング済み（良好）

---

## 🏗 段階別リファクタリング計画

### Phase 1: Fat Model解消 (最優先)
**期間**: 1-2日  
**リスク**: 中  
**影響範囲**: モデル層・ビジネスロジック

#### 1.1 MyStorySectionの分離
```ruby
# 現在: 264行の巨大モデル
# 分離後:
- MyStorySection (基本CRUD・バリデーション)
- MyStorySectionJsonManager (JSONB操作専用)
- MyStorySectionPositionManager (位置管理専用)
- MyStorySectionValidator (複雑バリデーション)
```

#### 1.2 Articleモデルの責務分離
```ruby
# 現在: 108行
# 分離後:
- Article (基本CRUD・関連)
- ArticleSearchService (検索ロジック)
- ArticlePublishingService (公開管理)
- ArticleRecommendationService (関連記事取得)
```

#### 1.3 SiteSettingの最適化
```ruby
# 現在: 90行（キャッシュ・メタプログラミング混在）
# 最適化:
- SiteSetting (基本設定管理)
- SiteSettingCacheManager (キャッシュ専用)
- 設定種別の定数最適化
```

### Phase 2: Fat Controller解消
**期間**: 2-3日  
**リスク**: 中  
**影響範囲**: コントローラー層・画面遷移

#### 2.1 Admin::MyStorySectionsController
```ruby
# 現在: 166行
# 分離後:
- Controller (基本CRUD)
- MyStorySectionOrderingService (位置変更)
- MyStorySectionStateService (有効/無効切り替え)
```

#### 2.2 Admin::SectionContentsController
```ruby
# 現在: 103行
# 分離後:
- Controller (基本操作)
- SectionContentActivationService (アクティベーション)
- SectionContentValidationService (バリデーション)
```

#### 2.3 Admin::ArticlesController
```ruby
# 現在: 94行
# 分離後:
- Controller (基本CRUD)
- ArticlePublishingService (公開制御)
- ArticleAssociationService (カテゴリ・タグ管理)
```

### Phase 3: Helper層最適化
**期間**: 1日  
**リスク**: 低  
**影響範囲**: ビューレンダリング

#### 3.1 ApplicationHelperの分割
```ruby
# 現在: 99行（複数責務）
# 分離後:
- ApplicationHelper (基本ヘルパー)
- MarkdownHelper (Markdown処理専用)
- NavigationHelper (ナビゲーション専用)
- TimeHelper (日時処理専用)
```

### Phase 4: 共通化・DRY化
**期間**: 1-2日  
**リスク**: 低  
**影響範囲**: 全体

#### 4.1 重複ロジック統合
- CRUD操作の共通化
- バリデーション処理の統合
- エラーハンドリングの統一

#### 4.2 Concern作成
- `Positionable` (位置管理共通)
- `Publishable` (公開状態管理共通)
- `JsonStorable` (JSONB操作共通)

---

## ⚡️ 実行スケジュール

### Day 1: Phase 1.1-1.2 (Fat Model解消 Part 1)
- MyStorySectionの分離
- Articleモデルの責務分離
- **動作確認**: 全機能テスト

### Day 2: Phase 1.3 + Phase 2.1 (Fat Model完了 + Controller開始)
- SiteSetting最適化
- Admin::MyStorySectionsController分離
- **動作確認**: 管理画面テスト

### Day 3: Phase 2.2-2.3 (Fat Controller完了)
- 残りコントローラー分離
- **動作確認**: API・フロントエンド全テスト

### Day 4: Phase 3-4 (Helper最適化・DRY化)
- ApplicationHelper分割
- 共通化・Concern作成
- **最終動作確認**: 全機能統合テスト

---

## 🛡 リスク管理

### 高リスク作業
1. **MyStorySection分離**: JSONBロジック複雑
2. **Article検索機能**: PostgreSQL全文検索
3. **コントローラー分離**: 画面遷移への影響

### 対策
- **細かいコミット**: 各クラス分離ごとにコミット
- **段階的テスト**: 分離後即座に動作確認
- **ロールバック準備**: 問題発生時の迅速切り戻し

### 動作確認項目
- [ ] 管理画面全機能 (ログイン・CRUD・公開制御)
- [ ] 公開サイト全ページ (ポートフォリオ・ブログ・My Story)
- [ ] API機能 (/api/v1/*)
- [ ] 画像アップロード・表示
- [ ] 検索機能
- [ ] OGP・SEO機能

---

## 📊 成果指標

### コード品質
- **Fat Model解消**: 100行以下に分割
- **Fat Controller解消**: 50行以下に削減
- **重複コード**: 50%以上削減

### 保守性向上
- **責務明確化**: 各クラス単一責任
- **テスト容易性**: モック・スタブ活用可能
- **拡張性**: 新機能追加時の影響最小化

### パフォーマンス
- **処理速度**: 既存と同等以上
- **メモリ使用量**: 増加なし
- **データベース**: クエリ最適化維持

---

## 🔄 継続的改善

### 今回リファクタリング後
1. **コードレビュー文化**: 新機能追加時の品質チェック
2. **定期リファクタリング**: 月1回の品質確認
3. **メトリクス監視**: ファイル行数・複雑度の定期確認

### 今後の方針
- **技術的負債**: 蓄積させない開発サイクル
- **設計パターン**: Service Object・Command Pattern活用
- **テスト**: リファクタリング後のテストコード追加

---

## 📝 ドキュメント更新予定

### 更新対象
- `CLAUDE.md`: リファクタリング実施記録
- `README.md`: アーキテクチャ更新
- `/docs/development/`: 設計思想・パターン記録

### 作成予定
- Service Object設計指針
- Controller薄化ガイドライン  
- モデル責務分離パターン

---

## ✅ チェックリスト

### 実行前
- [ ] 現状のGitHubプッシュ
- [ ] 動作確認環境準備
- [ ] バックアップ取得

### 各Phase完了時
- [ ] 全機能動作確認
- [ ] テスト実行
- [ ] コミット・プッシュ
- [ ] 進捗記録

### 完了時
- [ ] 最終動作確認
- [ ] ドキュメント更新
- [ ] 今後の開発方針確認
- [ ] Phase 3.4機能調整への移行準備

---

**計画策定日**: 2025-12-13  
**実行予定期間**: 2025-12-13 〜 2025-12-16  
**責任者**: Claude (リファクタリング実行) + ユーザー (動作確認・承認)