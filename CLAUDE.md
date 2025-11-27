# Portfolio Site Project - Claude Memory

## プロジェクト概要
シニアエンジニアの技術発信・ポートフォリオサイト
- Ruby on Rails 8.0.1 + Tailwind CSS
- PostgreSQL + Sidekiq + OpenAI API
- AWS Lightsail（本番環境）

## 現在の状況
- **フェーズ**: Phase 1（仕様策定完了）
- **仕様書**: `/docs/specifications/spec.md`
- **開発方針**: アジャイル開発（2週間スプリント）

## 主要機能
1. **ポートフォリオCMS**: 8セクション構成の縦スクロール型
2. **技術ブログ**: Markdown + カテゴリ階層 + 検索
3. **メディアライブラリ**: 画像管理・最適化
4. **SEO/AEO**: 自動最適化 + AI連携
5. **管理画面**: セキュリティ強化（パス変更可能）

## 技術的な決定事項
- **管理画面パス**: デフォルト `/admin` だが変更可能
- **AI機能**: GPT APIで記事要約・キーワード抽出
- **画像処理**: WebP自動変換 + 遅延読み込み
- **検索**: PostgreSQL全文検索
- **SNS埋め込み**: oEmbed対応

## 次のタスク
- [ ] 画面モック作成
- [ ] DB schema設計  
- [ ] API設計
- [ ] Sprint 0: 環境構築開始

## 開発ルール
- テスト駆動開発（TDD）
- 各Sprint後に本番デプロイ
- コードレビュー必須

## 重要な決定
- カテゴリは2階層まで
- 検索UIは開発中に決定
- AI機能は非同期処理（Sidekiq）
- 管理画面セキュリティ重視

## 参考資料
- 仕様書: `/docs/specifications/spec.md`
- My Story画像: `/Users/tsuyoshi/Downloads/My-Story-なぜ要件定義から実装まで一人でできるのか-宮川-剛-11-26-2025_01_11_PM.png`