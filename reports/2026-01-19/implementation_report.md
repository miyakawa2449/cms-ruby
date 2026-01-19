# 2026-01-19 実装レポート

## 概要
OGP専用サムネイルの保存・参照機能を追加し、ブログ記事ページのヒーロー周りの左右バランスを改善した。併せて運用用の一括生成タスクを用意した。

## 実装内容
- OGP専用画像をArticleに追加し、管理画面の保存/プレビュー/生成フローに統合
- 画像トリミングでOGP画像（1200x630）を生成し、`ogp_image`として保存
- OGPメタタグの優先順位を `ogp_image` > `thumbnail_image` > デフォルト に変更
- OGPメタタグのサイズ表記を1200x630に統一
- 管理画面一覧にOGP画像の有無バッジを追加
- 既存記事向けにOGP画像を一括生成するRakeタスクを追加
- ブログ記事ページのヘッダーを本文と同じグリッド幅に揃え、余白バランスを改善

## 変更ファイル
- `app/models/article.rb`
- `app/controllers/admin/articles_controller.rb`
- `app/views/admin/articles/_form.html.erb`
- `app/javascript/controllers/thumbnail_editor_controller.js`
- `app/services/meta_tags_service.rb`
- `app/views/admin/articles/index.html.erb`
- `app/views/blog/show.html.erb`
- `app/views/blog/index.html.erb`
- `lib/tasks/ogp_images.rake`
- `.kiro/specs/ogp-dedicated-thumbnail/design.md`
- `.kiro/specs/ogp-dedicated-thumbnail/requirements.md`
- `.kiro/specs/ogp-dedicated-thumbnail/tasks.md`

## 動作確認
- JSビルド: `npm run build`
- OGP一括生成タスク: `bin/rails ogp:generate_images`
  - DB/ストレージ不整合により、欠損ファイルはエラー（FileNotFound）となることを確認

## 課題・注意点
- DBのBlob情報に対して実ファイルが欠損している記事があるため、`ogp:generate_images` が失敗するケースあり
- 欠損分は再アップロード後に再生成済み

## 次のアクション候補
- 欠損ファイルの洗い出しと復旧方針の整理
- OGP専用画像運用の定着（既存記事の再生成/補完）

