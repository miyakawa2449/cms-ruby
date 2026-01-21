# ロゴ表示修正指示書

## 問題

トップページ（https://example.test）でロゴ画像が表示されず、フォールバックの「M」マークが表示されている。

### エラー内容

```
Logo display error: Can't resolve image into URL: undefined method 'polymorphic_url'
```

### 原因

`SiteAssetsService` の `site_logo` メソッドで、Active Storageの画像オブジェクトを直接 `image_tag` に渡しているが、Service クラスのコンテキストでは `polymorphic_url` が使用できないためエラーになっている。

---

## 修正対象ファイル

`app/services/site_assets_service.rb`

---

## 修正内容

### 修正前（8〜21行目付近）

```ruby
def site_logo(options = {})
  begin
    logo_setting = SiteSetting.logo
    
    if logo_setting&.image_value&.attached?
      css_class = options[:class] || 'h-8 w-auto'
      alt_text = options[:alt] || 'サイトロゴ'
      
      ApplicationController.helpers.image_tag(
        logo_setting.image_value, 
        class: css_class, 
        alt: alt_text
      )
    else
      fallback_logo(options)
    end
  rescue => e
    Rails.logger.error "Logo display error: #{e.message}"
    fallback_logo(options)
  end
end
```

### 修正後

```ruby
def site_logo(options = {})
  begin
    logo_setting = SiteSetting.logo
    
    if logo_setting&.image_value&.attached?
      css_class = options[:class] || 'h-8 w-auto'
      alt_text = options[:alt] || 'サイトロゴ'
      
      # 明示的にURLを生成（polymorphic_url問題を回避）
      logo_url = Rails.application.routes.url_helpers.rails_storage_proxy_path(
        logo_setting.image_value, 
        only_path: true
      )
      
      ApplicationController.helpers.image_tag(
        logo_url, 
        class: css_class, 
        alt: alt_text
      )
    else
      fallback_logo(options)
    end
  rescue => e
    Rails.logger.error "Logo display error: #{e.message}"
    fallback_logo(options)
  end
end
```

---

## 修正のポイント

1. Active Storageの画像オブジェクトを直接 `image_tag` に渡すのではなく、先に `rails_storage_proxy_path` でURLを生成する
2. `Rails.application.routes.url_helpers` を使うことで、Serviceクラス内でもURL生成が可能になる
3. `only_path: true` で相対パスを生成（HTTPSの問題を回避）

---

## デプロイ手順

修正後、以下のコマンドでデプロイ：

```bash
git add app/services/site_assets_service.rb
git commit -m "Fix logo display by explicitly generating URL path"
git push

# サーバー上で
cd ~/web-server/portfolio
git pull
docker compose --env-file .env.production -p portfolio-prod -f docker-compose.production.yml build --no-cache portfolio-web portfolio-worker
docker compose --env-file .env.production -p portfolio-prod -f docker-compose.production.yml up -d
```

---

## 動作確認

1. https://example.test/ にアクセス
2. ヘッダー左上にロゴ画像が表示されることを確認
3. フォールバックの「M」マークではなく、管理画面で登録したロゴ画像が表示されること

---

## 注意事項

- CSSで無理やりロゴを生成するような回避策は使わないこと
- 画像は Active Storage で正しく管理されており、DBにも登録済み（`SiteSetting.logo.image_value.attached?` は `true`）
- 問題はコードのURL生成部分のみ
