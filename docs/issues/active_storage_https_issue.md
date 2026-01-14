# Active Storage 画像表示問題 - 調査依頼

## 概要

開発環境でActive Storageの画像が表示されない問題が発生しています。
ブラウザコンソールに`ERR_SSL_PROTOCOL_ERROR`が表示されます。

## 環境

- Ruby on Rails 8.1.1
- Docker Compose開発環境
- Active Storage (Disk service)
- Tailwind CSS
- Turbo Drive (Hotwire)

## 症状

ブログ記事のサムネイル画像が表示されず、以下のエラーがブラウザコンソールに出力される：

```
GET https://localhost:3000/rails/active_storage/disk/... net::ERR_SSL_PROTOCOL_ERROR
```

開発環境は`http://localhost:3000`で動作しているが、画像URLが`https://`で生成されている。

## 調査結果

### サーバー側の確認

curlコマンドで確認したところ、**サーバー側は正しくHTTPでURLを生成している**：

1. HTMLソースの画像URL:
```
src="http://localhost:3000/rails/active_storage/blobs/redirect/..."
```
→ 正しく`http://`

2. リダイレクト先URL:
```
location: http://localhost:3000/rails/active_storage/disk/...
```
→ 正しく`http://`

### ブラウザ側の問題

しかし、ブラウザのコンソールエラーでは`https://localhost:3000`でアクセスしようとしている。

これは以下のキャッシュが原因と推測：
- Turbo Driveのページキャッシュ
- Service Workerキャッシュ
- ブラウザのディスクキャッシュ

ハードリフレッシュ (`Cmd+Shift+R`) やブラウザキャッシュクリアでも解消しない。

## 実施した修正

### 1. `config/initializers/active_storage_url_options.rb`

開発環境用のURL設定を追加：

```ruby
Rails.application.config.after_initialize do
  if Rails.env.production?
    # 本番環境: HTTPS
    url_options = {
      host: ENV.fetch("APP_HOST", "miyakawa.codes"),
      protocol: "https"
    }
  else
    # 開発・テスト環境: HTTP
    url_options = {
      host: "localhost",
      port: 3000,
      protocol: "http"
    }
  end

  Rails.application.routes.default_url_options = url_options
  ActiveStorage::Current.url_options = url_options
end
```

ミドルウェアにも同様の設定を追加。

### 2. 確認事項

修正後、curlで確認するとHTTPで正しく生成されている。
しかしブラウザでは依然として`https://`でアクセスしようとする。

## 質問

1. **なぜブラウザは`https://`でアクセスしようとするのか？**
   - サーバーは`http://`で返している
   - ブラウザキャッシュをクリアしても解消しない

2. **Turbo Driveがキャッシュを保持している可能性は？**
   - Turbo Driveのキャッシュをクリアする方法は？

3. **HSTSヘッダーが設定されている可能性は？**
   - 開発環境でHSTSが有効になっていないか確認する方法は？

4. **他に確認すべき設定はあるか？**

## 関連ファイル

- `config/initializers/active_storage_url_options.rb`
- `config/environments/development.rb`
- `config/storage.yml`
- `app/views/blog/show.html.erb`

## 補足

- 本番環境ではSSLが有効なため、この問題は発生しないはず
- 開発環境でのみ発生する問題
