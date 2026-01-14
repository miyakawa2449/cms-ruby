# Claude Code - Phase 5.1 画像編集機能 修正指示書

## 📅 作成日: 2025-12-30
## 🎯 目的: Phase 5.1 画像編集機能の実装修正

---

## 🚨 現在の問題

### 問題1: Cropper.jsの実装方法が間違っている
- **現状**: importmap（CDN）でCropper.jsを読み込もうとしている
- **問題**: このプロジェクトはesbuildを使用しているため、CDNではなくnpmパッケージとして追加する必要がある
- **影響**: Stimulusコントローラーが動作せず、画像編集機能が使えない

### 問題2: CSP（Content Security Policy）違反
- **現状**: CDNからCSSを読み込もうとしてCSPでブロックされている
- **エラー**: `Loading the stylesheet 'https://cdn.jsdelivr.net/npm/cropperjs@1.6.1/dist/cropper.min.css' violates the following Content Security Policy directive`

### 問題3: Stimulusコントローラーが接続されていない
- **現状**: ブラウザコンソールに `MediaEditorController connected` が表示されない
- **原因**: Cropper.jsが正しく読み込まれていないため、コントローラーの初期化に失敗している

---

## ✅ 修正手順（必ずこの順番で実行）

### Step 1: importmap.rbからCropper.jsの設定を削除

**ファイル**: `config/importmap.rb`

**削除する行**:
```ruby
# Image editing library
pin "cropperjs", to: "https://cdn.jsdelivr.net/npm/cropperjs@1.6.1/dist/cropper.esm.js"
```

**理由**: esbuildプロジェクトではimportmapではなくnpmパッケージを使用する

---

### Step 2: Cropper.jsをnpmパッケージとしてインストール

**実行コマンド**:
```bash
docker-compose exec web npm install cropperjs
```

**確認方法**:
```bash
# package.jsonに追加されたことを確認
docker-compose exec web cat package.json | grep cropperjs
```

**期待される出力**:
```json
"cropperjs": "^1.6.1"
```

---

### Step 3: Cropper.jsのCSSをアプリケーションに統合

**ファイル**: `app/assets/stylesheets/application.tailwind.css`

**追加する場所**: ファイルの先頭（`@tailwind base;`の前）

**追加するコード**:
```css
/* Cropper.js styles for image editing */
@import 'cropperjs/dist/cropper.css';

@tailwind base;
@tailwind components;
@tailwind utilities;
```

**理由**: esbuildでバンドルするため、CSSもnpmパッケージから読み込む

---

### Step 4: admin.html.erbからCDNのCSSリンクを削除

**ファイル**: `app/views/layouts/admin.html.erb`

**削除する行**:
```erb
<!-- Cropper.js CSS -->
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/cropperjs@1.6.1/dist/cropper.min.css">
```

**理由**: Step 3でアプリケーションCSSに統合したため、CDNリンクは不要

---

### Step 5: CSP設定からcdn.jsdelivr.netを削除（オプション）

**ファイル**: `config/initializers/content_security_policy.rb`

**削除する行**:
```ruby
# CDN (Cropper.js等)
"https://cdn.jsdelivr.net",
```

**理由**: CDNを使用しなくなったため、CSP設定も不要

---

### Step 6: JavaScriptを再ビルド

**実行コマンド**:
```bash
docker-compose exec web npm run build
```

**期待される出力**:
```
✓ app/assets/builds/application.js  XXX.XkB
✓ app/assets/builds/application.js.map  XXX.XkB

Done in XXXms
```

**確認方法**:
```bash
# Cropper.jsがバンドルに含まれていることを確認
grep -c "cropper" app/assets/builds/application.js
```

**期待される出力**: `48` 以上の数値（Cropper.jsのコードが含まれている）

---

### Step 7: Webサーバーを再起動

**実行コマンド**:
```bash
docker-compose restart web
```

**待機時間**: 5秒

**確認方法**:
```bash
docker-compose logs web --tail 20
```

**期待される出力**:
```
web-1  | => Booting Puma
web-1  | => Rails 8.1.1 application starting in development
web-1  | * Listening on http://0.0.0.0:3000
```

---

### Step 8: 動作確認

**ブラウザで確認**:
1. `http://localhost:3000/admin-secure-panel-miyakawa2449/media` にアクセス
2. 任意の画像をクリックして詳細画面を開く
3. ブラウザの開発者ツール（F12）を開く
4. Consoleタブを確認

**期待される出力**:
```
MediaEditorController connected
```

**画像編集ボタンをクリック**:
1. 「画像を編集」ボタンをクリック
2. Consoleに以下が表示されることを確認:
```
MediaEditorController open called
imageUrl: /rails/active_storage/blobs/...
mediaId: 5
```

3. 編集モーダルが開くことを確認
4. Cropper.jsの編集UIが表示されることを確認

---

## 🔍 トラブルシューティング

### 問題: `npm install cropperjs` が失敗する

**エラー例**:
```
npm ERR! code ENOENT
npm ERR! syscall open
```

**解決方法**:
```bash
# package-lock.jsonを削除して再インストール
docker-compose exec web rm package-lock.json
docker-compose exec web npm install
docker-compose exec web npm install cropperjs
```

---

### 問題: ビルド後もCropper.jsが含まれていない

**確認コマンド**:
```bash
grep -c "cropper" app/assets/builds/application.js
```

**出力が0の場合**:
1. `app/javascript/controllers/media_editor_controller.js` の先頭を確認:
```javascript
import Cropper from "cropperjs"
```

2. この行が存在することを確認
3. 存在しない場合は追加して再ビルド

---

### 問題: モーダルが開かない

**確認方法**:
```bash
# Stimulusコントローラーが登録されているか確認
grep "media-editor" app/javascript/controllers/index.js
```

**期待される出力**:
```javascript
import MediaEditorController from "./media_editor_controller"
application.register("media-editor", MediaEditorController)
```

**登録されていない場合**:
`app/javascript/controllers/index.js` に以下を追加:
```javascript
import MediaEditorController from "./media_editor_controller"
application.register("media-editor", MediaEditorController)
```

---

### 問題: CSSが適用されていない

**確認方法**:
```bash
# application.tailwind.cssにimportが追加されているか確認
head -5 app/assets/stylesheets/application.tailwind.css
```

**期待される出力**:
```css
/* Cropper.js styles for image editing */
@import 'cropperjs/dist/cropper.css';

@tailwind base;
```

**追加されていない場合**: Step 3を再実行

---

## 📋 最終チェックリスト

修正完了後、以下をすべて確認してください：

- [ ] `config/importmap.rb` からCropper.jsのpin設定を削除した
- [ ] `npm install cropperjs` を実行し、package.jsonに追加された
- [ ] `app/assets/stylesheets/application.tailwind.css` にCropper.jsのCSSをimportした
- [ ] `app/views/layouts/admin.html.erb` からCDNのCSSリンクを削除した
- [ ] `npm run build` を実行し、エラーなく完了した
- [ ] `grep -c "cropper" app/assets/builds/application.js` で48以上の数値が返る
- [ ] `docker-compose restart web` を実行した
- [ ] ブラウザのConsoleに `MediaEditorController connected` が表示される
- [ ] 「画像を編集」ボタンをクリックするとモーダルが開く
- [ ] Cropper.jsの編集UIが正しく表示される
- [ ] アスペクト比の変更ができる
- [ ] 回転・反転ができる
- [ ] 保存ボタンが動作する

---

## 🎯 実装完了の定義

以下の機能がすべて動作すること：

1. **画像編集モーダルの表示**
   - 「画像を編集」ボタンをクリックするとモーダルが開く
   - Cropper.jsのUIが正しく表示される

2. **クロップ機能**
   - マウスでドラッグして切り抜き範囲を指定できる
   - 範囲のリサイズができる

3. **アスペクト比固定**
   - 自由/1:1/4:3/16:9/3:2のボタンが動作する
   - 選択したアスペクト比で切り抜き範囲が固定される

4. **回転機能**
   - 左回転ボタンで90度反時計回りに回転する
   - 右回転ボタンで90度時計回りに回転する

5. **反転機能**
   - 左右反転ボタンで水平反転する
   - 上下反転ボタンで垂直反転する

6. **リセット機能**
   - リセットボタンで編集内容がリセットされる

7. **保存機能**
   - 「新規保存」ボタンで新しいファイルとして保存される
   - 「上書き保存」ボタンで元の画像が置き換えられる
   - 保存後、ページがリロードされて更新された画像が表示される

---

## 🚨 重要な注意事項

### このプロジェクトの技術スタック

**JavaScript/CSSバンドラー**: esbuild
- **package.json**: JavaScriptライブラリはすべてnpmで管理
- **npm run build**: esbuildでバンドル
- **importmap.rb**: 基本的なStimulus/Turboのみ（外部ライブラリは使わない）

### 間違った実装パターン（絶対にやらないこと）

❌ **CDNから直接読み込む**:
```ruby
# config/importmap.rb
pin "cropperjs", to: "https://cdn.jsdelivr.net/..."  # ❌ 間違い
```

❌ **HTMLにCDNリンクを追加**:
```html
<link rel="stylesheet" href="https://cdn.jsdelivr.net/...">  <!-- ❌ 間違い -->
```

### 正しい実装パターン

✅ **npmパッケージとして追加**:
```bash
npm install cropperjs  # ✅ 正しい
```

✅ **CSSをアプリケーションに統合**:
```css
@import 'cropperjs/dist/cropper.css';  /* ✅ 正しい */
```

✅ **JavaScriptでimport**:
```javascript
import Cropper from "cropperjs"  // ✅ 正しい
```

---

## 📝 実装後の報告フォーマット

修正完了後、以下の形式で報告してください：

```
Phase 5.1 画像編集機能 修正完了報告

## 実施した修正
1. ✅ importmap.rbからCropper.js削除
2. ✅ npm install cropperjs実行
3. ✅ application.tailwind.cssにCSS追加
4. ✅ admin.html.erbからCDNリンク削除
5. ✅ npm run build実行
6. ✅ docker-compose restart web実行

## 動作確認結果
- ✅ MediaEditorController connected 表示確認
- ✅ 画像編集モーダル表示確認
- ✅ Cropper.js UI表示確認
- ✅ クロップ機能動作確認
- ✅ アスペクト比変更動作確認
- ✅ 回転・反転機能動作確認
- ✅ 保存機能動作確認

## 変更ファイル一覧
- config/importmap.rb（削除）
- package.json（cropperjs追加）
- app/assets/stylesheets/application.tailwind.css（import追加）
- app/views/layouts/admin.html.erb（CDNリンク削除）
- app/assets/builds/application.js（再ビルド）

## スクリーンショット
（画像編集モーダルのスクリーンショットを添付）
```

---

## 🔗 参考資料

- **Cropper.js公式ドキュメント**: https://github.com/fengyuanchen/cropperjs
- **esbuild公式ドキュメント**: https://esbuild.github.io/
- **Stimulus公式ドキュメント**: https://stimulus.hotwired.dev/
- **Phase 5.1仕様書**: `docs/specifications/features/phase5_media_library.md`

---

**作成者**: Kiro (AI Assistant)
**最終更新**: 2025-12-30
**対象**: Claude Code v2.0.72
