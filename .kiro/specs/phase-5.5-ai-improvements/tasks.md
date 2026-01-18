# Phase 5.5: AI機能改善 - タスクリスト

**Phase**: 5.5  
**機能名**: AI機能改善  
**実施期間**: 2026-01-19 〜 2026-01-20（2日間）

---

## 📋 タスク概要

- **総タスク数**: 11
- **完了**: 0
- **進行中**: 0
- **未着手**: 11

---

## ✅ タスクリスト

### Task 1: Setup and Dependencies
- [ ] 1.1 Chart.jsのインストール（package.json）
- [ ] 1.2 ルーティング追加（config/routes.rb）
- [ ] 1.3 AiGenerationモデルにstructure feature_type追加

### Task 2: AI::StructureSuggester - プロンプト改善
- [ ] 2.1 プロンプトの改善（より具体的な構成提案）
- [ ] 2.2 日本語出力の精度向上
- [ ] 2.3 エラーハンドリング強化
- [ ] 2.4 ユニットテストの実装

### Task 3: AI::UsageStatisticsService - 統計サービス実装
- [ ] 3.1 UsageStatisticsServiceクラスの作成
- [ ] 3.2 daily_usageメソッドの実装
- [ ] 3.3 monthly_usageメソッドの実装
- [ ] 3.4 usage_by_featureメソッドの実装
- [ ] 3.5 total_costメソッドの実装
- [ ] 3.6 top_featuresメソッドの実装
- [ ] 3.7 export_dataメソッドの実装
- [ ] 3.8 ユニットテストの実装

### Task 4: AI::BedrockClient - リトライ機能追加
- [ ] 4.1 リトライロジックの実装（最大3回、指数バックオフ）
- [ ] 4.2 タイムアウト設定（30秒）
- [ ] 4.3 カスタム例外クラスの追加（BedrockApiError, BedrockTimeoutError）
- [ ] 4.4 エラーログの詳細化
- [ ] 4.5 ユニットテストの実装

### Task 5: Admin::AiController - 構成提案エンドポイント追加
- [ ] 5.1 suggest_structureアクションの実装
- [ ] 5.2 パラメータバリデーション
- [ ] 5.3 エラーハンドリング
- [ ] 5.4 統合テストの実装

### Task 6: Admin::AiUsageController - 統計ページ実装
- [ ] 6.1 AiUsageControllerの作成
- [ ] 6.2 indexアクションの実装
- [ ] 6.3 exportアクションの実装（CSV）
- [ ] 6.4 期間フィルター処理の実装
- [ ] 6.5 統合テストの実装

### Task 7: 記事編集画面 - 構成提案UI追加
- [ ] 7.1 構成提案セクションの追加（_form.html.erb）
- [ ] 7.2 トピック入力欄の実装
- [ ] 7.3 構成提案ボタンの実装
- [ ] 7.4 提案結果表示エリアの実装
- [ ] 7.5 本文挿入ボタンの実装

### Task 8: AI使用統計ページ - ビュー実装
- [ ] 8.1 index.html.erbの作成
- [ ] 8.2 期間フィルターUIの実装
- [ ] 8.3 サマリーカードの実装
- [ ] 8.4 日別使用量グラフの実装（Chart.js）
- [ ] 8.5 機能別使用量グラフの実装（Chart.js）
- [ ] 8.6 使用履歴テーブルの実装
- [ ] 8.7 CSVエクスポートボタンの実装

### Task 9: Stimulusコントローラー - 構成提案機能追加
- [ ] 9.1 suggestStructureメソッドの実装
- [ ] 9.2 displayStructureメソッドの実装
- [ ] 9.3 insertStructureメソッドの実装
- [ ] 9.4 showStructureErrorメソッドの実装
- [ ] 9.5 ローディング表示の実装

### Task 10: プロンプト品質向上 - 各サービスの改善
- [ ] 10.1 TitleSuggesterのプロンプト改善
- [ ] 10.2 SummaryGeneratorのプロンプト改善
- [ ] 10.3 TagSuggesterのプロンプト改善
- [ ] 10.4 SlugGeneratorのプロンプト改善
- [ ] 10.5 SeoMetaGeneratorのプロンプト改善

### Task 11: Final Integration and Testing
- [ ] 11.1 全機能の統合テスト
- [ ] 11.2 エラーケースのテスト
- [ ] 11.3 パフォーマンステスト
- [ ] 11.4 ドキュメント更新（README.md）
- [ ] 11.5 本番環境デプロイ準備

---

## 📊 進捗状況

```
[                    ] 0% (0/11 タスク完了)
```

---

## 🔄 タスク実行順序

### Day 1（2026-01-19）
1. Task 1: Setup and Dependencies
2. Task 2: AI::StructureSuggester - プロンプト改善
3. Task 3: AI::UsageStatisticsService - 統計サービス実装
4. Task 4: AI::BedrockClient - リトライ機能追加
5. Task 5: Admin::AiController - 構成提案エンドポイント追加

### Day 2（2026-01-20）
6. Task 6: Admin::AiUsageController - 統計ページ実装
7. Task 7: 記事編集画面 - 構成提案UI追加
8. Task 8: AI使用統計ページ - ビュー実装
9. Task 9: Stimulusコントローラー - 構成提案機能追加
10. Task 10: プロンプト品質向上 - 各サービスの改善
11. Task 11: Final Integration and Testing

---

## 📝 備考

### 依存関係
- Task 2, 3, 4は並行実行可能
- Task 5はTask 2完了後
- Task 6はTask 3完了後
- Task 7, 9はTask 5完了後
- Task 8はTask 6完了後
- Task 10は他のタスクと並行実行可能
- Task 11は全タスク完了後

### 重要な注意事項
- Chart.jsのバージョンは4.4.0以上を使用
- BedrockClientのリトライ機能はテスト環境で十分に検証
- AI使用統計ページのグラフ描画は3秒以内に完了すること
- CSVエクスポートは大量データでもメモリエラーが発生しないこと

---

**作成日**: 2026-01-18  
**作成者**: Kiro  
**ステータス**: 実装待ち
