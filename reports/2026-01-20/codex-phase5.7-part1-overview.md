# Phase 5.7 テストカバレッジ向上 - Codex依頼書 Part 1: 概要

**依頼日**: 2026-01-20  
**依頼者**: Kiro（仕様管理担当）  
**Phase**: 5.7 テストカバレッジ向上  
**作業種別**: テスト作成・実装（150件）

---

## 📋 なぜCodexに直接依頼するのか

### Phase 5.6での実績

Codexは Phase 5.6 で以下の優れた成果を達成しました：

1. **42件のテスト作成**（すべて成功、0 failures）
2. **問題発見**: フラグメントキャッシュの欠落を発見
3. **主体的な実装**: テスト作成だけでなく、キャッシュ実装も追加
4. **高品質**: コードの品質、テストの網羅性が優秀

**Kiroの評価**: ⭐⭐⭐⭐⭐ 5/5

### Claude Codeの課題

Phase 5.6で判明した課題：
- テストの重要性を認識していない
- フラグメントキャッシュの実装を見落とし
- テストファイルを作成しなかった

**結論**: テスト作成はCodexの専門領域であり、直接依頼が最適

---

## 🎯 作業目標

### 定量目標
1. **テスト総数**: 150件以上
2. **テストカバレッジ**: 85%以上
3. **テスト実行時間**: 30分以内
4. **成功率**: 95%以上（失敗は5%以内）

### 定性目標
1. テストの保守性向上
2. バグ検出率向上
3. リファクタリングの安全性向上
4. 開発速度の向上

---

## 📚 参照ドキュメント（必読）

### Phase 5.7 仕様書（優先度: 高）
1. **機能仕様書**: `docs/specifications/features/5.7_test_coverage.md`
   - テスト全体の概要
   - 150件のテスト内訳
   - カバレッジ目標

2. **要件定義**: `.kiro/specs/phase-5.7-test-coverage/requirements.md`
   - ユーザーストーリー
   - 受入基準
   - 機能要件

3. **タスクリスト**: `.kiro/specs/phase-5.7-test-coverage/tasks.md`
   - 10タスクの詳細
   - 実行順序
   - 6日間のスケジュール

4. **テスト仕様書**: `.kiro/specs/phase-5.7-test-coverage/test_spec.md`
   - 具体的なテストケース
   - テストコードのサンプル
   - カバレッジ目標

5. **設計書**: `.kiro/specs/phase-5.7-test-coverage/design.md`
   - 技術的詳細
   - モック戦略
   - CI/CD統合

### Phase 5.6 実績（参考）
6. **Phase 5.6 最終レビュー**: `reports/2026-01-19/kiro-final-review.md`
   - Codexの優れた実績
   - テスト作成のベストプラクティス
   - 成功パターン

---

## 📊 テスト内訳（150件）

### 1. ユニットテスト（75件）

#### AI機能テスト（60件）
- `spec/services/ai/title_suggester_spec.rb` - 10件
- `spec/services/ai/summary_generator_spec.rb` - 10件
- `spec/services/ai/tag_suggester_spec.rb` - 10件
- `spec/services/ai/slug_generator_spec.rb` - 10件
- `spec/services/ai/seo_meta_generator_spec.rb` - 10件
- `spec/services/ai/structure_suggester_spec.rb` - 10件

#### AI基盤テスト（15件）
- `spec/services/ai/bedrock_client_spec.rb` - 10件
- `spec/services/ai/usage_tracker_spec.rb` - 5件

### 2. 統合テスト（60件）

#### 記事CRUD（20件）
- `spec/requests/admin/articles_crud_spec.rb` - 20件

#### 認証・認可（15件）
- `spec/requests/admin/authentication_spec.rb` - 15件

#### APIエンドポイント（25件）
- `spec/requests/api/v1/articles_spec.rb` - 10件
- `spec/requests/api/v1/categories_spec.rb` - 5件
- `spec/requests/api/v1/tags_spec.rb` - 5件
- `spec/requests/api/v1/ai_spec.rb` - 5件

### 3. E2Eテスト（15件）

#### 記事作成フロー（10件）
- `spec/system/article_creation_spec.rb` - 10件

#### 画像・メディア（5件）
- `spec/system/media_upload_spec.rb` - 5件

---

次のファイル: Part 2 - 詳細タスク
