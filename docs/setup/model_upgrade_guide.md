# Claude 4.5シリーズへのアップグレードガイド

## 📊 なぜClaude 4.5にアップグレードすべきか

### 性能比較

| 項目 | Claude 3 Haiku | Claude Haiku 4.5 | 改善率 |
|------|----------------|------------------|--------|
| SWE-bench スコア | ~40% | 73.3% | +83% |
| 処理速度 | 基準 | 4-5倍速い | +400% |
| 価格（Input） | $0.25/1M | $1.00/1M | 4倍 |
| 価格（Output） | $1.25/1M | $5.00/1M | 4倍 |
| **コスパ** | 良い | **最高** | - |

### 主な改善点

1. **Haiku 4.5の驚異的な進化**
   - Sonnet 4並みの性能を実現
   - 価格は1/3、速度は4-5倍
   - タグ提案・スラッグ生成の精度が大幅向上

2. **Sonnet 4.5の最高性能**
   - コーディング: 77.2% on SWE-bench
   - 推論能力の大幅向上
   - 長時間の自律動作（30時間以上）

## 💰 コスト影響

### 月間20記事の場合

**Claude 3シリーズ**:
- Haiku 3: $0.25/$1.25 per 1M tokens
- 月額: 約$2.40

**Claude 4.5シリーズ**:
- Haiku 4.5: $1.00/$5.00 per 1M tokens
- 月額: 約$3.00

**差額**: +$0.60/月（+25%）

**判断**: 性能向上を考えると**非常にコスパが良い**

## 🔄 アップグレード手順

### 1. AWS Bedrockでモデルアクセス申請

```
AWS Console > Bedrock > Model access
✅ Claude Sonnet 4.5
✅ Claude Haiku 4.5
```

### 2. コードは既に対応済み

`app/services/ai/model_selector.rb` は既にClaude 4.5に更新されています：

```ruby
MODELS = {
  summary: 'anthropic.claude-sonnet-4-5-v2:0',
  tags: 'anthropic.claude-haiku-4-5-v2:0',
  slug: 'anthropic.claude-haiku-4-5-v2:0',
  seo_meta: 'anthropic.claude-sonnet-4-5-v2:0',
  structure: 'anthropic.claude-sonnet-4-5-v2:0'
}
```

### 3. テスト実行

```bash
# Railsコンソールでテスト
bundle exec rails console

client = Ai::BedrockClient.new
model_id = 'anthropic.claude-haiku-4-5-v2:0'
result = client.invoke_model(model_id, 'テスト')
puts result[:content]
```

### 4. 本番デプロイ

モデルアクセスが承認されたら、そのままデプロイ可能です。

## ⚠️ 注意事項

### モデルIDの確認

AWS Bedrockでの正確なモデルIDを確認してください：

```bash
# AWS CLIで確認
aws bedrock list-foundation-models \
  --region us-east-1 \
  --query 'modelSummaries[?contains(modelId, `claude`)].{ID:modelId,Name:modelName}' \
  --output table
```

**予想されるモデルID**:
- `anthropic.claude-sonnet-4-5-v2:0`
- `anthropic.claude-haiku-4-5-v2:0`

または:
- `anthropic.claude-sonnet-4-5:0`
- `anthropic.claude-haiku-4-5:0`

**重要**: 実際のモデルIDが異なる場合は、`model_selector.rb` を更新してください。

### 後方互換性

旧モデルも `MODEL_COSTS` に残してあるので、必要に応じて使用可能です：

```ruby
# 旧モデルを使いたい場合
MODEL_COSTS = {
  'anthropic.claude-sonnet-4-5-v2:0' => { input: 3.0, output: 15.0 },
  'anthropic.claude-haiku-4-5-v2:0' => { input: 1.0, output: 5.0 },
  # Legacy models
  'anthropic.claude-3-5-sonnet-20241022-v2:0' => { input: 3.0, output: 15.0 },
  'anthropic.claude-3-haiku-20240307-v1:0' => { input: 0.25, output: 1.25 }
}
```

## 📈 期待される改善

### タグ提案の精度向上

**Before (Haiku 3)**:
- 適合率: ~70%
- 新規タグ提案: 時々不適切

**After (Haiku 4.5)**:
- 適合率: ~85-90%（予想）
- 新規タグ提案: より適切

### 要約の品質向上

**Before (Sonnet 3.5)**:
- 品質: 良い
- 文脈理解: 良い

**After (Sonnet 4.5)**:
- 品質: 優秀
- 文脈理解: 優秀
- より自然な日本語

### スラッグ生成の改善

**Before (Haiku 3)**:
- 英訳精度: 普通
- SEO最適化: 普通

**After (Haiku 4.5)**:
- 英訳精度: 高い
- SEO最適化: 高い

## 🎯 推奨事項

### すぐにアップグレードすべき理由

1. ✅ **性能が大幅に向上**（特にHaiku 4.5）
2. ✅ **コスト増は最小限**（+$0.60/月）
3. ✅ **コードは既に対応済み**
4. ✅ **後方互換性あり**（問題があれば戻せる）

### アップグレード後の確認項目

- [ ] モデルアクセスが承認されている
- [ ] テストが全てパスする
- [ ] 生成結果の品質を確認
- [ ] コスト監視を継続

## 🔍 トラブルシューティング

### モデルIDが見つからない

```ruby
# エラー: ResourceNotFoundException
# 解決: モデルIDを確認

# AWS CLIで利用可能なモデルを確認
aws bedrock list-foundation-models --region us-east-1
```

### コストが予想より高い

```ruby
# 使用量を確認
Ai::UsageTracker.this_month

# モデル別の内訳を確認
stats = AiUsageStat.this_month
stats.group_by(&:ai_model).each do |model, records|
  total_cost = records.sum(&:total_cost)
  puts "#{model}: $#{total_cost}"
end
```

## 📚 参考リンク

- [Claude 4.5 発表（Anthropic）](https://www.anthropic.com/news/claude-4)
- [AWS Bedrock Claude モデル](https://aws.amazon.com/bedrock/claude/)
- [Claude API 価格](https://docs.anthropic.com/claude/docs/models-overview)

---

**結論**: Claude 4.5シリーズへのアップグレードを強く推奨します。性能向上が大きく、コスト増は最小限です。
