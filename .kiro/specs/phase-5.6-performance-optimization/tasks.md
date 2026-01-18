# Phase 5.6: パフォーマンス最適化 - タスクリスト

**Phase**: 5.6  
**機能名**: パフォーマンス最適化  
**実施期間**: 2026-01-21 〜 2026-01-25（5日間）

---

## 📋 タスク概要

- **総タスク数**: 13
- **完了**: 0
- **進行中**: 0
- **未着手**: 13

---

## ✅ タスクリスト

### Task 1: Setup and Dependencies
- [ ] 1.1 Bullet gemのインストール（Gemfile）
- [ ] 1.2 rack-mini-profiler gemのインストール
- [ ] 1.3 redis gemのインストール
- [ ] 1.4 Docker ComposeにRedisコンテナ追加
- [ ] 1.5 環境変数設定（REDIS_URL）

### Task 2: Bullet gemの設定
- [ ] 2.1 development.rbでBullet有効化
- [ ] 2.2 アラート表示設定
- [ ] 2.3 ログ出力設定
- [ ] 2.4 動作確認

### Task 3: N+1問題の解消 - ブログ一覧ページ
- [ ] 3.1 BlogController#indexのクエリ最適化
- [ ] 3.2 includes/preloadの適用
- [ ] 3.3 Bulletでの検証
- [ ] 3.4 パフォーマンステストの実装

### Task 4: N+1問題の解消 - 記事詳細ページ
- [ ] 4.1 BlogController#showのクエリ最適化
- [ ] 4.2 関連記事のクエリ最適化
- [ ] 4.3 Bulletでの検証
- [ ] 4.4 パフォーマンステストの実装

### Task 5: N+1問題の解消 - 管理画面
- [ ] 5.1 Admin::ArticlesController#indexのクエリ最適化
- [ ] 5.2 Admin::CategoriesController#indexのクエリ最適化
- [ ] 5.3 Admin::TagsController#indexのクエリ最適化
- [ ] 5.4 Bulletでの検証

### Task 6: スロークエリログの設定
- [ ] 6.1 slow_query_logger.rbの作成
- [ ] 6.2 100ms以上のクエリ検出設定
- [ ] 6.3 ログファイル出力設定
- [ ] 6.4 動作確認

### Task 7: Redis環境構築
- [ ] 7.1 docker-compose.ymlにRedis追加
- [ ] 7.2 cable.ymlの設定
- [ ] 7.3 cache.ymlの作成
- [ ] 7.4 production.rbのキャッシュストア設定
- [ ] 7.5 Redis接続テスト

### Task 8: セッションストアの移行
- [ ] 8.1 session_store.rbの作成
- [ ] 8.2 Redis Storeの設定
- [ ] 8.3 動作確認（ログイン・ログアウト）
- [ ] 8.4 統合テストの実装

### Task 9: フラグメントキャッシュの実装
- [ ] 9.1 サイドバーキャッシュの実装
- [ ] 9.2 記事一覧キャッシュの実装
- [ ] 9.3 人気記事キャッシュの実装
- [ ] 9.4 キャッシュヒット率の測定

### Task 10: キャッシュ無効化戦略の実装
- [ ] 10.1 CacheSweeperモジュールの作成
- [ ] 10.2 Articleモデルでの実装
- [ ] 10.3 Categoryモデルでの実装
- [ ] 10.4 Tagモデルでの実装
- [ ] 10.5 キャッシュ無効化テストの実装

### Task 11: CacheMonitorServiceの実装
- [ ] 11.1 CacheMonitorServiceクラスの作成
- [ ] 11.2 statsメソッドの実装
- [ ] 11.3 calculate_hit_rateメソッドの実装
- [ ] 11.4 ユニットテストの実装

### Task 12: アセット最適化
- [ ] 12.1 CSS/JS圧縮設定の確認
- [ ] 12.2 lazy_image_tagヘルパーの実装
- [ ] 12.3 ブログ一覧での画像遅延読み込み適用
- [ ] 12.4 記事詳細での画像遅延読み込み適用
- [ ] 12.5 ポートフォリオでの画像遅延読み込み適用

### Task 13: Final Integration and Testing
- [ ] 13.1 全ページのパフォーマンステスト
- [ ] 13.2 キャッシュヒット率の測定
- [ ] 13.3 N+1問題の最終確認
- [ ] 13.4 パフォーマンスベンチマークの実行
- [ ] 13.5 ドキュメント更新（README.md）
- [ ] 13.6 本番環境デプロイ準備

---

## 📊 進捗状況

```
[                    ] 0% (0/13 タスク完了)
```

---

## 🔄 タスク実行順序

### Day 1（2026-01-21）
1. Task 1: Setup and Dependencies
2. Task 2: Bullet gemの設定
3. Task 3: N+1問題の解消 - ブログ一覧ページ

### Day 2（2026-01-22）
4. Task 4: N+1問題の解消 - 記事詳細ページ
5. Task 5: N+1問題の解消 - 管理画面
6. Task 6: スロークエリログの設定

### Day 3（2026-01-23）
7. Task 7: Redis環境構築
8. Task 8: セッションストアの移行
9. Task 9: フラグメントキャッシュの実装

### Day 4（2026-01-24）
10. Task 10: キャッシュ無効化戦略の実装
11. Task 11: CacheMonitorServiceの実装
12. Task 12: アセット最適化

### Day 5（2026-01-25）
13. Task 13: Final Integration and Testing

---

## 📝 備考

### 依存関係
- Task 2はTask 1完了後
- Task 3, 4, 5はTask 2完了後（並行実行可能）
- Task 7は独立して実行可能
- Task 8, 9はTask 7完了後
- Task 10はTask 9完了後
- Task 11はTask 9完了後（並行実行可能）
- Task 12は独立して実行可能
- Task 13は全タスク完了後

### 重要な注意事項
- Redisのメモリ容量に注意（512MB）
- キャッシュ無効化のタイミングを慎重に設計
- 本番環境でのRedis接続エラー時の動作確認
- パフォーマンステストは実データに近い環境で実施

---

**作成日**: 2026-01-18  
**作成者**: Kiro  
**ステータス**: 実装待ち
