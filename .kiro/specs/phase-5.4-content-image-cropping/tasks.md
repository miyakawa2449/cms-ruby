# Phase 5.4: 本文内画像トリミング機能 - 実装タスク

## 概要

本文内画像のトリミング機能を実装する。既存のサムネイル編集機能（`thumbnail_editor_controller.js`）を参考に、
800x600px（4:3固定）のトリミング機能を提供する。

## 実装タスク

### 1. フロントエンド: Stimulus Controller作成

- [ ] 1.1 ContentImageEditorControllerを作成
  - ファイル: `app/javascript/controllers/content_image_editor_controller.js`
  - 既存の`thumbnail_editor_controller.js`を参考にする
  - 主な違い: 出力サイズ800x600px、アスペクト比4:3固定、複数サイズ生成なし
  - _要件: FR-1, FR-3_

- [ ] 1.2 ファイル選択処理を実装
  - `selectFile(event)`メソッド
  - ファイル形式チェック（クライアント側）
  - ファイルサイズチェック（10MB以下）
  - FileReaderで画像読み込み
  - _要件: FR-1.1, FR-5.1, FR-5.2_

- [ ] 1.3 モーダル表示制御を実装
  - `openModal(file)`メソッド
  - `close()`メソッド
  - ESCキーでモーダルを閉じる
  - オーバーレイクリックでモーダルを閉じる
  - _要件: FR-1.1, NFR-2_

- [ ] 1.4 Cropper.js初期化を実装
  - `initCropper(imageUrl)`メソッド
  - アスペクト比4:3で固定
  - トリミング範囲の初期設定
  - _要件: FR-1.2, FR-1.3, FR-3.1_

- [ ] 1.5 プレビュー更新を実装
  - `updatePreview()`メソッド
  - リアルタイムでプレビュー更新
  - 800x600pxのプレビュー表示
  - _要件: FR-1.4, NFR-2_

- [ ] 1.6 画像Blob生成を実装
  - `getImageBlob()`メソッド
  - 800x600pxのCanvasを生成
  - JPEG形式、品質92%でBlob化
  - _要件: FR-1.5_

- [ ] 1.7 サーバーアップロード処理を実装
  - `uploadImage(blob, altText, caption)`メソッド
  - FormData作成
  - Fetch APIでPOSTリクエスト
  - CSRF トークン設定
  - ローディング表示
  - _要件: FR-2, FR-4, NFR-3_

- [ ] 1.8 Markdown挿入処理を実装
  - `insertMarkdown(markdown)`メソッド
  - エディタのカーソル位置に挿入
  - _要件: FR-4.2_

- [ ] 1.9 エラーハンドリングを実装
  - `showError(message)`メソッド
  - `showSuccess(message)`メソッド
  - トースト通知表示
  - _要件: FR-5, NFR-2_

- [ ] 1.10 Controllerをアプリケーションに登録
  - ファイル: `app/javascript/controllers/index.js`
  - `content-image-editor`として登録
  - _要件: FR-3_

### 2. フロントエンド: ビュー作成

- [ ] 2.1 トリミングモーダルのパーシャルを作成
  - ファイル: `app/views/admin/articles/_content_image_editor_modal.html.erb`
  - モーダル構造（オーバーレイ、コンテンツ）
  - ヘッダー（タイトル、閉じるボタン）
  - トリミング範囲選択エリア
  - プレビュー表示エリア
  - alt属性入力フィールド（必須）
  - キャプション入力フィールド（オプション）
  - 保存/キャンセルボタン
  - Tailwind CSSでスタイリング
  - _要件: FR-3.2_

- [ ] 2.2 記事編集画面に画像挿入ボタンを追加
  - ファイル: `app/views/admin/articles/_form.html.erb`
  - 「📷 画像を挿入」ボタン
  - 非表示のファイル入力要素
  - data-controller属性の設定
  - data-action属性の設定
  - _要件: FR-1.1_

- [ ] 2.3 記事編集画面にモーダルを読み込み
  - ファイル: `app/views/admin/articles/_form.html.erb`
  - `<%= render 'content_image_editor_modal' %>`を追加
  - _要件: FR-3_

### 3. バックエンド: Controller拡張

- [ ] 3.1 ArticleImagesControllerのcreateアクションを拡張
  - ファイル: `app/controllers/admin/article_images_controller.rb`
  - パラメータバリデーション（image, alt_text必須）
  - ファイル形式チェック（サーバー側）
  - ファイルサイズチェック（サーバー側）
  - _要件: FR-5, NFR-3_

- [ ] 3.2 MediaMetadata作成処理を実装
  - `create_media_metadata(image, alt_text)`メソッド
  - width: 800, height: 600を設定
  - alt_textを保存
  - 使用状況追跡（track_usage）
  - _要件: FR-2.2_

- [ ] 3.3 Markdownコード生成処理を実装
  - `generate_markdown(image_url, alt_text, caption)`メソッド
  - キャプションなし: Markdown形式
  - キャプションあり: HTML形式（figure/figcaption）
  - XSS対策（HTMLエスケープ）
  - _要件: FR-4.1, NFR-3_

- [ ] 3.4 エラーレスポンス処理を実装
  - `render_error(message)`メソッド
  - 422ステータスコードでJSON返却
  - _要件: FR-5_

- [ ] 3.5 成功レスポンス処理を実装
  - JSONレスポンス生成
  - markdown, url, alt_text, caption, filename, width, heightを返却
  - _要件: FR-4_

### 4. ルーティング確認

- [ ] 4.1 ルーティングが正しく設定されているか確認
  - ファイル: `config/routes.rb`
  - `POST /admin/articles/:article_id/images`が存在するか確認
  - 既存のルーティングを使用（変更不要）
  - _要件: FR-2_

### 5. テスト実装

- [ ] 5.1 Controller単体テストを作成
  - ファイル: `spec/controllers/admin/article_images_controller_spec.rb`
  - 正常系: 画像アップロード成功
  - 正常系: MediaMetadata作成
  - 正常系: Markdown形式（キャプションなし）
  - 正常系: HTML形式（キャプションあり）
  - 異常系: 画像ファイル未選択
  - 異常系: alt属性未入力
  - 異常系: 不正なファイル形式
  - 異常系: ファイルサイズ超過
  - _要件: すべて_

- [ ] 5.2 MediaMetadataモデルテストを確認
  - ファイル: `spec/models/media_metadata_spec.rb`
  - 既存テストが正しく動作するか確認
  - _要件: FR-2.2_

### 6. 手動テスト・動作確認

- [ ] 6.1 基本機能の動作確認
  - 画像選択時にモーダルが表示される
  - トリミング範囲を調整できる
  - プレビューがリアルタイムで更新される
  - alt属性を入力できる
  - キャプションを入力できる（オプション）
  - 保存ボタンでアップロードされる
  - Markdownがエディタに挿入される
  - _要件: FR-1, FR-3, FR-4_

- [ ] 6.2 エラーハンドリングの動作確認
  - 画像以外のファイルを選択した場合のエラー表示
  - 10MB以上のファイルを選択した場合のエラー表示
  - alt属性未入力時のエラー表示
  - アップロード失敗時のエラー表示
  - _要件: FR-5_

- [ ] 6.3 UI/UXの動作確認
  - モーダルの表示/非表示がスムーズ
  - ローディング表示が適切
  - ESCキーでモーダルを閉じられる
  - オーバーレイクリックでモーダルを閉じられる
  - 成功メッセージが表示される
  - _要件: NFR-2_

- [ ] 6.4 レスポンシブ対応の確認
  - デスクトップ表示
  - タブレット表示
  - モバイル表示
  - _要件: NFR-2_

- [ ] 6.5 セキュリティの確認
  - ファイル形式チェックが機能する
  - ファイルサイズ制限が機能する
  - XSS対策が機能する（alt属性、キャプション）
  - CSRF対策が機能する
  - _要件: NFR-3_

- [ ] 6.6 パフォーマンスの確認
  - トリミングモーダル表示 < 1秒
  - 画像アップロード < 5秒（5MB画像）
  - プレビュー更新 < 0.5秒
  - _要件: NFR-1_

### 7. ドキュメント更新

- [ ] 7.1 実装完了後、仕様書のステータスを更新
  - ファイル: `docs/specifications/features/phase5_4_content_image_cropping.md`
  - ステータスを「🟢 実装完了」に変更
  - 実装履歴を追加

- [ ] 7.2 README更新（必要に応じて）
  - 新機能の説明を追加

## チェックポイント

### Checkpoint 1: フロントエンド基本実装完了後
- ContentImageEditorControllerが作成されている
- トリミングモーダルが表示される
- Cropper.jsが動作する
- プレビューが更新される
- **確認**: ブラウザで画像選択からトリミングまで動作するか

### Checkpoint 2: アップロード機能実装完了後
- サーバーへのアップロードが成功する
- MediaMetadataが作成される
- Markdownコードが生成される
- エディタに挿入される
- **確認**: 画像選択からMarkdown挿入まで一連の流れが動作するか

### Checkpoint 3: エラーハンドリング実装完了後
- ファイル形式チェックが動作する
- ファイルサイズチェックが動作する
- エラーメッセージが表示される
- **確認**: 各種エラーケースで適切なメッセージが表示されるか

### Checkpoint 4: テスト実装完了後
- すべてのテストがパスする
- カバレッジが目標値を達成している
- **確認**: `bundle exec rspec`を実行してすべてのテストがパスするか

## 実装時の注意事項

### 既存機能との整合性
- サムネイル編集機能（`thumbnail_editor_controller.js`）と同様のUI/UX
- 既存の画像アップロード機能（`article_images_controller.rb`）を拡張
- MediaMetadataモデルの既存機能を活用

### コードの品質
- ESLintルールに従う
- Rubocopルールに従う
- コメントを適切に記述
- 変数名・メソッド名は分かりやすく

### セキュリティ
- ファイル形式チェックは必ずクライアント・サーバー両方で実施
- XSS対策を徹底（HTMLエスケープ）
- CSRF対策を確認

### パフォーマンス
- 画像処理はクライアント側で実行
- 不要なDOM操作を避ける
- メモリリークに注意（Cropperの破棄）

## 参考ファイル

### 既存実装
- `app/javascript/controllers/thumbnail_editor_controller.js` - サムネイル編集機能
- `app/controllers/admin/article_images_controller.rb` - 画像アップロード機能
- `app/views/admin/articles/_thumbnail_editor_modal.html.erb` - サムネイルモーダル

### ドキュメント
- `docs/specifications/features/phase5_4_content_image_cropping.md` - 詳細仕様書
- `.kiro/specs/phase5-4-content-image-cropping/requirements.md` - 要件定義
- `.kiro/specs/phase5-4-content-image-cropping/design.md` - 設計書

## 完了条件

すべてのタスクが完了し、以下の条件を満たすこと：

1. ✅ すべての機能要件が実装されている
2. ✅ すべての非機能要件が満たされている
3. ✅ すべての受け入れ基準をクリアしている
4. ✅ すべてのテストがパスしている
5. ✅ 手動テストで問題が発見されていない
6. ✅ コードレビューが完了している
7. ✅ ドキュメントが更新されている
