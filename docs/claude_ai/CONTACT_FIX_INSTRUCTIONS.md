# お問い合わせ機能修正指示書

## 問題一覧

| # | 問題 | 状況 |
|---|------|------|
| 1 | 管理画面のお問い合わせメニューがない | ナビゲーションから欠落 |
| 2 | メール通知が来ない | AWS SES設定が必要 |
| 3 | 送信完了メッセージが消えるのが早い | 3秒→5秒に延長、スクロール追加 |

---

## 修正ファイル一覧

| ファイルパス | 修正内容 |
|-------------|---------|
| `app/views/admin/shared/_navigation.html.erb` | お問い合わせメニュー追加 |
| `config/initializers/aws_ses.rb` | AWS SES SDK設定 |
| `app/mailers/application_mailer.rb` | 送信元アドレス設定 |
| `app/mailers/contact_mailer.rb` | 新規作成 |
| `app/views/contact_mailer/admin_notification.html.erb` | 新規作成 |
| `app/views/contact_mailer/admin_notification.text.erb` | 新規作成 |
| `app/views/contact_mailer/auto_reply.html.erb` | 新規作成 |
| `app/views/contact_mailer/auto_reply.text.erb` | 新規作成 |
| `app/jobs/contact_notification_job.rb` | メール送信処理追加 |
| `app/javascript/controllers/contact_form_controller.js` | UX改善 |
| `.env.example` | SES環境変数追加 |

---

## 修正1: 管理画面ナビゲーションにお問い合わせメニューを追加

### ファイル
`app/views/admin/shared/_navigation.html.erb`

### 修正内容

「コンテンツ管理」セクションの最後（My Storyの後）に以下を追加：

```erb
    <%= link_to admin_contacts_path, 
                class: "flex items-center px-4 py-2 text-sm font-medium rounded-md #{controller_name == 'contacts' ? 'bg-gray-800 text-white' : 'text-gray-300 hover:bg-gray-700 hover:text-white'}" do %>
      <svg class="mr-3 h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" 
              d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
      </svg>
      お問い合わせ
    <% end %>
```

---

## 修正2: AWS SES メール送信設定

### 環境変数（.env.production に追加）

```bash
# AWS SES設定
AWS_SES_REGION=ap-northeast-1
AWS_SES_ACCESS_KEY_ID=your_ses_access_key
AWS_SES_SECRET_ACCESS_KEY=your_ses_secret_key
MAIL_FROM=noreply@example.test
ADMIN_EMAIL=contact@example.test
```

**重要:**
- `ap-northeast-3`（大阪）ではSESは利用不可。`ap-northeast-1`（東京）を使用してください。
- IAMアクセスキーにSES送信権限（`ses:SendEmail`）が必要です。
- `MAIL_FROM` のドメインはSESで検証済みである必要があります。

### IAMポリシー例

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ses:SendEmail",
        "ses:SendRawEmail"
      ],
      "Resource": "*"
    }
  ]
}
```

### ファイル: `config/initializers/aws_ses.rb`

修正済みファイルを参照してください。AWS SDK経由でメール送信するよう設定しています。

---

## 修正3: ContactMailer の作成

### ファイル: `app/mailers/contact_mailer.rb`

```ruby
class ContactMailer < ApplicationMailer
  # 管理者への通知メール
  def admin_notification(contact)
    @contact = contact
    
    mail(
      to: ENV.fetch('ADMIN_EMAIL', 'contact@example.test'),
      subject: "[お問い合わせ] #{contact.subject} - #{contact.name}様より"
    )
  end
  
  # 問い合わせ者への自動返信メール
  def auto_reply(contact)
    @contact = contact
    
    mail(
      to: contact.email,
      subject: "【Miyakawa Codes】お問い合わせありがとうございます"
    )
  end
end
```

### メールテンプレート

以下のファイルを `app/views/contact_mailer/` に配置：
- `admin_notification.html.erb`
- `admin_notification.text.erb`
- `auto_reply.html.erb`
- `auto_reply.text.erb`

---

## 修正4: 送信完了UXの改善

### ファイル: `app/javascript/controllers/contact_form_controller.js`

1. メッセージ表示時間を3秒→5秒に延長
2. 成功時にフォーム上部へスクロール

---

## デプロイ手順

```bash
# ローカルで
git add .
git commit -m "Add contact menu, AWS SES email notifications, and UX improvements"
git push

# サーバー上で
cd ~/web-server/portfolio
git pull

# .env.production にSES設定を追加
nano .env.production
# AWS_SES_REGION=ap-northeast-1
# AWS_SES_ACCESS_KEY_ID=...
# AWS_SES_SECRET_ACCESS_KEY=...
# MAIL_FROM=noreply@example.test
# ADMIN_EMAIL=contact@example.test

# 再ビルド＆再起動
docker compose --env-file .env.production -p portfolio-prod -f docker-compose.production.yml build --no-cache portfolio-web portfolio-worker
docker compose --env-file .env.production -p portfolio-prod -f docker-compose.production.yml up -d
```

---

## 動作確認

1. **管理画面メニュー**: 左メニューに「お問い合わせ」が表示される
2. **お問い合わせ送信テスト**: フロントエンドでテスト送信
3. **Slack通知**: 引き続き動作することを確認
4. **管理者メール**: `ADMIN_EMAIL` にメールが届く
5. **自動返信メール**: 送信者にメールが届く
6. **送信完了UX**: メッセージが5秒間表示され、フォーム上部にスクロールする

---

## AWS SES セットアップ（未設定の場合）

### 1. SESでドメイン/メールアドレスを検証

AWS Console → SES → Verified identities → Create identity

- ドメイン検証: `example.test` のDNSにレコード追加
- または、メールアドレス検証: `contact@example.test` に確認メール

### 2. サンドボックスから本番へ移行

SESは最初サンドボックスモード（検証済みアドレスにのみ送信可能）です。
本番利用には、AWSサポートへ申請が必要です。

AWS Console → SES → Account dashboard → Request production access

### 3. IAMユーザーにSES権限を付与

IAM → Users → (対象ユーザー) → Add permissions → Attach policies
→ `AmazonSESFullAccess` または上記のカスタムポリシー
