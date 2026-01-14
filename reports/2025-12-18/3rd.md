# 作業報告 3rd - CSP設定更新でGTM/GA4/Clarity対応

## 日付
2025-12-18

## 作業者
Claude Code

## 概要
Google Tag Manager（GTM）がContent Security Policy（CSP）によってブロックされていた問題を解決。CSP設定を更新してGTM、Google Analytics 4、Microsoft Clarityを許可。

## Git情報
- Branch: main
- Last Commit: dc3456e - fix: CSP設定を更新してGTM/GA4/Clarityを許可
- 変更ファイル数: 1ファイル

## 実施内容

### 1. CSPエラーの原因と対策
#### エラー内容
```
Loading the script 'https://www.googletagmanager.com/gtm.js?id=GTM-MMWTS38R' 
violates the following Content Security Policy directive: 
"script-src 'self' 'unsafe-inline' 'unsafe-eval' https://cdn.jsdelivr.net"
```

#### 原因
- デフォルトのCSP設定がコメントアウトされていた
- GTM関連ドメインが許可されていなかった

### 2. CSP設定の全面更新
#### 更新ファイル
`/config/initializers/content_security_policy.rb`

#### 許可したサービスとドメイン
1. **Google Tag Manager**
   - `googletagmanager.com`
   - `www.googletagmanager.com`

2. **Google Analytics 4**
   - `google-analytics.com`
   - `analytics.google.com`
   - `*.google-analytics.com`

3. **Microsoft Clarity**
   - `clarity.ms`
   - `*.clarity.ms`

4. **その他**
   - Google Fonts（fonts.googleapis.com、fonts.gstatic.com）
   - jsDelivr CDN（cdn.jsdelivr.net）

### 3. CSPディレクティブ詳細

| ディレクティブ | 設定内容 | 用途 |
|--------------|---------|------|
| `script_src` | self, unsafe-inline, unsafe-eval, GTM, GA4, Clarity, CDN | JavaScriptの実行 |
| `style_src` | self, unsafe-inline, Google Fonts | CSSの適用 |
| `font_src` | self, data, Google Fonts | Webフォント |
| `img_src` | self, data, https, GTM, GA4, Clarity | 画像読み込み |
| `connect_src` | self, GA4, Analytics, Clarity | API通信 |
| `frame_src` | self, GTM | iframeプレビュー |
| `worker_src` | self, blob | Web Worker（Clarity用） |
| `object_src` | none | セキュリティ強化 |

## 技術的詳細

### CSP実装のポイント
1. **柔軟性とセキュリティのバランス**
   - `unsafe-inline`と`unsafe-eval`を許可（GTM動的スクリプト対応）
   - 必要最小限のドメインのみ許可

2. **将来の拡張性**
   - ワイルドカード使用（*.clarity.ms、*.google-analytics.com）
   - コメントで追加方法を記載

3. **開発/本番の互換性**
   - Report-Onlyモードのオプション記載
   - Nonce生成のオプション記載

### Docker環境での反映
```bash
docker-compose restart web
```
- 初期化ファイルの変更のため再起動必須

## 次回の課題
1. 404/500エラーページ作成
2. 本番環境でのCSP動作確認
3. GTMタグの正常発火確認
4. MVP最終統合テスト

## 確認項目
- [x] CSP設定ファイル更新
- [x] Docker環境再起動
- [x] GitHubへプッシュ完了
- [ ] ローカル環境でのGTM動作確認
- [ ] 本番環境デプロイ後の動作確認

## 申し送り事項
- CSP設定は`config/initializers/content_security_policy.rb`で管理
- 新しいサービス追加時は該当ディレクティブにドメイン追加
- 本番デプロイ時は`./scripts/deploy.sh --keep-ssl`を実行
- ブラウザキャッシュクリア（Ctrl+Shift+R）推奨