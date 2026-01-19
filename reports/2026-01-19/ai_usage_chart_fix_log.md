# AI使用統計グラフ不具合 修正ログ

## 概要
AI使用統計ページでChart.jsグラフが表示されない問題を調査・修正した。

## 発生していたエラー
- `Uncaught TypeError: Failed to resolve module specifier "chart.js". Relative references must start with either "/", "./", or "../".`
- `Uncaught TypeError: Chart is not a constructor`

## 原因
- ビュー内の`<script type="module">`で`chart.js`を直接importしていたが、ブラウザ側のモジュール解決に失敗していた。
- `bin/dev`ではCSSのみwatchされており、JSビルドが実行されず、`window.Chart`が提供されていない状態だった。
- 結果としてChart.jsが未ロードのまま描画処理が走り、`Chart is not a constructor`が発生した。

## 対応内容
1. Chart.jsをesbuildのバンドル対象に追加
   - `app/javascript/application.js`で`chart.js`をimportし、`window.Chart`として公開
2. グラフ描画のタイミングを遅延
   - `app/views/admin/ai_usage/index.html.erb`の描画処理を`turbo:load`/`DOMContentLoaded`後に実行
   - `Chart`が未ロードの場合は警告して終了するようにガード
3. JSビルドのwatchを追加
   - `Procfile.dev`に`js: npm run build -- --watch`を追加
4. JSの手動ビルドを実施
   - `npm run build`で`app/assets/builds/application.js`を更新

## 検証結果（ローカル）
- コンソールの`Chart is not a constructor`が消失
- グラフのX/Y軸と値が表示されることを確認

## 本番検証時のチェックポイント
- コンソールにChart.js関連のエラーが出ていないこと
- グラフが表示され、軸と値が描画されること

## 関連ファイル
- `app/javascript/application.js`
- `app/views/admin/ai_usage/index.html.erb`
- `Procfile.dev`
- `app/assets/builds/application.js`
