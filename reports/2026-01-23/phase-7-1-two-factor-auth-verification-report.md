## Phase 7.1: 二要素認証（2FA）- 検証レポート（最終）

### 検証サマリー
- ステータス: ✅ 合格
- 追加テスト: 2FA関連RSpecを実行（54 examples, 0 failures）
- 修正内容: 5件（2FA迂回リスクの解消、2FA有効化後のセッション処理、CSP対応、Turbo回避、ログインフローをOTP同時入力に統一）
- 問題点: なし（既知の不具合は解消済み）

### 指摘事項（修正済み）

1) **High: 2FAが迂回される可能性**（修正済み）
- 位置: `app/models/admin_user.rb`
- 内容: `:database_authenticatable` と `:two_factor_authenticatable` の併用はdevise-two-factorのREADMEで**セキュリティ上の問題**として明確に禁止。
- 対応: `:database_authenticatable` を削除し、` :two_factor_authenticatable` のみに変更。

2) **Medium: 2FA有効化直後に再度OTP要求される**（修正済み）
- 位置: `app/controllers/admin/two_factor_auth_controller.rb`
- 内容: 有効化後のセッションに2FA済みフラグがないため再認証が発生。
- 対応: `session[:two_factor_authenticated]` / `session[:two_factor_authenticated_at]` をセット。

3) **Medium: バックアップコードの切替・ボタンが本番で動作しない**（修正済み）
- 位置: `app/views/admin/two_factor_auth/verify.html.erb` / `app/views/admin/two_factor_auth/backup_codes.html.erb`
- 内容: 本番CSPで `unsafe-inline` が許可されていないため、インラインJSが無効化されていた。
- 影響: バックアップコードログイン切替ができず、コピー/ダウンロード/印刷ボタンが動かない。
- 対応: Stimulusコントローラへ移行（`backup_codes_controller.js`, `two_factor_verify_controller.js`）。

4) **High: 2FAログインが不安定（OTP未入力で422）**（修正済み）
- 位置: `app/controllers/application_controller.rb` / `app/views/admin_users/sessions/new.html.erb` / `app/models/admin_user.rb`
- 内容: `:database_authenticatable` を外した後、ログイン時に `otp_attempt` が必要だがUIが別画面フローのままで422になっていた。
- 影響: ログイン不能・2FA状態が不整合になる。
- 対応: ログイン画面にOTP入力欄を追加し、`otp_attempt` をDeviseに許可。バックアップコードも同欄で検証可能に変更。

5) **Medium: Turbo送信により2FA有効化画面遷移が停止**（修正済み）
- 位置: `app/views/admin/two_factor_auth/new.html.erb` / `app/views/admin/two_factor_auth/show.html.erb` / `app/views/admin/two_factor_auth/verify.html.erb`
- 内容: Turboのフォーム送信でリダイレクト必須要件を満たせず画面が停止。
- 対応: `data: { turbo: false }` でTurboを無効化。

### テスト結果
- 実行コマンド:
  - `docker compose exec web bin/rails db:test:prepare`
  - `docker compose exec web bundle exec rspec spec/models/admin_user_spec.rb spec/services/two_factor_auth/qr_code_generator_spec.rb spec/requests/admin/two_factor_auth_spec.rb`
- 結果:
  - **2FA関連RSpec: 54 examples, 0 failures**

### 確認済み実装内容
- 2FA設定画面・認証画面UI
- QRコード生成（Base64 PNG）
- バックアップコード生成/検証
- 信頼デバイス（30日）
- 2FA用コントローラ/ルーティング

### 既存機能への影響
- フルテスト未実行のため未評価。
- Admin配下の全コントローラに2FA判定が入るため、管理画面の挙動確認は推奨。
- 実動作確認: ログイン/2FA有効化/バックアップコードログインが正常に動作することを確認。

### 次のステップ
1) 本番環境での2FA有効化→再ログイン（OTP/バックアップ）確認
