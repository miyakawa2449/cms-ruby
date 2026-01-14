# Active Storage HTTPS問題 & 埋め込みCSP設定 修正手順

## 概要

この手順書では以下の2つの問題を解決します：

1. **Active Storage HTTPS問題** - 開発環境でブラウザがHTTPSでアクセスしようとする
2. **埋め込みコンテンツCSP設定** - YouTube/X/Facebook/Instagram/Threadsの埋め込みがブロックされる

---

## 修正ファイル一覧

| ファイル | 修正内容 |
|---------|---------|
| `config/initializers/content_security_policy.rb` | 開発環境対応 + 各種SNS埋め込みドメイン追加 |
| `config/environments/development.rb` | Active Storage Proxyモード有効化 |
| `app/views/layouts/application.html.erb` | Turboキャッシュ無効化（開発環境のみ） |

---

## 1. CSP設定の修正内容

### 追加されたドメイン

#### frame-src（iframe埋め込み用）
```
YouTube:
- https://www.youtube.com
- https://youtube.com
- https://www.youtube-nocookie.com

X (Twitter):
- https://platform.twitter.com
- https://twitter.com
- https://x.com
- https://platform.x.com

Facebook:
- https://www.facebook.com
- https://facebook.com
- https://web.facebook.com

Instagram:
- https://www.instagram.com
- https://instagram.com

Threads:
- https://www.threads.net
- https://threads.net
```

#### script-src（スクリプト用）
```
X (Twitter):
- https://platform.twitter.com
- https://platform.x.com

YouTube:
- https://www.youtube.com

Facebook:
- https://connect.facebook.net
- https://www.facebook.com

Instagram:
- https://www.instagram.com

Threads:
- https://www.threads.net
```

#### style-src（スタイル用）
```
X (Twitter):
- https://platform.twitter.com
- https://platform.x.com
```

#### img-src（画像用）
```
X (Twitter):
- https://pbs.twimg.com
- https://abs.twimg.com
- https://platform.twitter.com

YouTube:
- https://i.ytimg.com
- https://img.youtube.com

Facebook:
- https://www.facebook.com
- https://static.xx.fbcdn.net
- https://*.fbcdn.net

Instagram:
- https://www.instagram.com
- https://*.cdninstagram.com
- https://scontent.cdninstagram.com

Threads:
- https://www.threads.net
- https://*.threads.net

Active Storage:
- :blob
```

### 開発環境対応

```ruby
# 変更前
policy.default_src :self, :https

# 変更後
if Rails.env.development? || Rails.env.test?
  policy.default_src :self
else
  policy.default_src :self, :https
end
```

---

## 2. Active Storage Proxyモード

`development.rb` に追加：

```ruby
config.active_storage.resolve_model_to_route = :rails_storage_proxy
```

### 効果

- `/rails/active_storage/disk/...` へのリダイレクトが発生しない
- Railsがファイルを直接配信
- HTTPS/HTTPの問題を回避

---

## 3. Turboキャッシュ無効化

`application.html.erb` に追加：

```erb
<% if Rails.env.development? %>
  <meta name="turbo-cache-control" content="no-cache">
<% end %>
```

---

## 4. ブラウザ側の対応（必須）

### Chrome の HSTSキャッシュクリア

1. `chrome://net-internals/#hsts` にアクセス
2. 「Delete domain security policies」セクションで `localhost` を入力
3. 「Delete」をクリック
4. 「Query HSTS/PKP domain」で `localhost` を確認
   - 「Not found」と表示されればOK

### Turbo Driveキャッシュクリア（コンソール）

```javascript
Turbo.cache.clear();
window.location.reload(true);
```

---

## 5. 適用手順

### Claude Code で実行

```bash
# 1. 変更をステージング
git add config/initializers/content_security_policy.rb
git add config/environments/development.rb
git add app/views/layouts/application.html.erb

# 2. コミット
git commit -m "fix: Active Storage HTTPS問題修正 & SNS埋め込みCSP対応 (YouTube/X/Facebook/Instagram/Threads)"

# 3. プッシュ
git push origin main
```

### Docker再起動

```bash
docker compose down
docker compose build --no-cache
docker compose up
```

---

## 6. 動作確認

### Active Storage

```bash
# サーバー側URLを確認（HTTPであること）
curl -v http://localhost:3000/blog/your-article-slug 2>&1 | grep -i "active_storage"

# HSTSヘッダーがないことを確認
curl -I http://localhost:3000/ 2>&1 | grep -i "strict-transport"
```

### 埋め込みコンテンツ

1. ブログ記事編集画面で各種SNS URLを入力
2. プレビューでiframeが表示されることを確認
3. ブラウザコンソールでCSPエラーがないことを確認

対応プラットフォーム：
- YouTube
- X (Twitter)
- Facebook
- Instagram
- Threads

---

## 7. トラブルシューティング

### 画像がまだ表示されない場合

1. **シークレットウィンドウでテスト**
   - HSTSやキャッシュの影響を排除

2. **別ブラウザでテスト**
   - Firefox, Safari等

3. **ブラウザ拡張機能を確認**
   - 「HTTPS Everywhere」等を無効化

### CSPエラーが発生する場合

ブラウザコンソールでエラーメッセージを確認し、不足しているドメインを追加してください。

```
Refused to frame 'https://example.com/' because it violates the following CSP directive: "frame-src ..."
```

---

## 変更履歴

- 2024-12-21: 初版作成
  - Active Storage Proxyモード追加
  - YouTube/X.com埋め込み用CSPドメイン追加
  - Facebook/Instagram/Threads埋め込み用CSPドメイン追加
  - 開発環境でのHTTPS強制除去
  - Turboキャッシュ無効化追加
