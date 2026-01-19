# OGP専用サムネイル保存・参照機能 - 設計書

## 1. アーキテクチャ概要

- 既存の `thumbnail_image`（4:3）に加え、`ogp_image`（1200x630）を `Article` に追加する。
- 管理画面のトリミングモーダルで 4:3 と OGP を同時生成し、保存時に両方のファイルを送信する。
- OGPメタタグの生成は `MetaTagsService` で `ogp_image` を優先し、未設定時は既存の `thumbnail_image` からフォールバック生成する。
- 既存記事については、RakeタスクでサムネイルからOGP画像を一括生成する。

## 2. データモデル

### 2.1 Active Storage

- `Article` に以下を追加:
  - `has_one_attached :ogp_image`

### 2.2 画像仕様

- `thumbnail_image`（記事表示用）: 1200x900, 4:3
- `ogp_image`（OGP用）: 1200x630, 1.9:1

## 3. UI/UX 設計

### 3.1 管理画面（記事編集）

- サムネイル編集モーダル内に「OGP用プレビュー」を既存のプレビュー枠として維持。
- 保存時に以下2枚を生成・保存:
  - `thumbnail_image`（4:3）
  - `ogp_image`（1.9:1, 中央切り出し）
- フォームに `ogp_image` 用の隠しファイル入力を追加し、`DataTransfer` で投入。

### 3.2 管理画面（記事一覧）

- OGP画像の有無をバッジ等で表示。
- OGP未設定の絞り込みフィルタを追加（任意）。

## 4. メタタグ生成

- `MetaTagsService#article_meta_tags` の OGP画像生成を以下順序で決定:
  1. `ogp_image` が存在すればそれを使用
  2. 未設定の場合は `thumbnail_image` の `resize_to_fill` で生成
  3. どちらも無ければ既定の OGP 画像
- `og:image` の width/height は 1200x630 を基準に統一

## 5. 画像生成ロジック

### 5.1 管理画面の生成

- `thumbnail_editor_controller.js` で 4:3 を生成後、中央切り出しで 1200x630 の OGP 画像を作成。
- 生成した `ogp_image` をフォームに投入して送信。

### 5.2 既存記事の一括生成

- Rakeタスクで `thumbnail_image` が存在し `ogp_image` が未設定のものだけ処理。
- 1200x630 をセンタークロップで生成。
- 成功/スキップ/失敗をログ出力。

## 6. API/フォーム設計

- `Admin::ArticlesController` の強いパラメータに `:ogp_image` を追加。
- 既存の `thumbnail_image` 更新フローを維持。

## 7. 正確性プロパティ（Property-Based Testing）

- 任意の入力画像から生成される `ogp_image` は常に 1200x630 の縦横比を満たす。
- `ogp_image` が存在する場合、OGPメタタグの `og:image` が必ず `ogp_image` のURLになる。
- `ogp_image` が無い場合、`thumbnail_image` から生成されるフォールバックが常に動作する。

## 8. エッジケース

- 画像が小さすぎる場合: `resize_to_fill` が拡大処理を行う（許容）。
- `ogp_image` が削除された場合: フォールバックへ切替。
- 既存記事で `thumbnail_image` が未設定の場合: OGP生成はスキップ。

## 9. 影響範囲

- `app/models/article.rb`
- `app/javascript/controllers/thumbnail_editor_controller.js`
- `app/views/admin/articles/_form.html.erb`
- `app/views/admin/articles/index.html.erb`
- `app/services/meta_tags_service.rb`
- `lib/tasks/`（Rakeタスク追加）

## 10. 移行方針

- 既存記事への影響はフォールバックで維持。
- 運用上必要であれば一括生成タスクを実行。

