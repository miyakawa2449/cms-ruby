# Requirements Document

## Introduction

開発環境のデータベースが空になった際に、本番環境からデータをエクスポートし、開発環境にインポートできる機能を実装する。管理画面からボタン操作で実行でき、データベースレコードとActive Storageの添付ファイル（画像など）を含むZIPファイルとして扱う。エクスポート対象には、管理者ユーザ、記事、カテゴリ、タグ、セクション情報（Section、SectionContent、MyStorySection）、お問い合わせ（Contact）、サイト設定が含まれる。

## Glossary

- **System**: データベースエクスポート/インポート機能全体
- **Export_Service**: データをJSON形式でエクスポートし、添付ファイルと共にZIPファイルを生成するサービス
- **Import_Service**: ZIPファイルを解凍し、データベースとActive Storageを復元するサービス
- **Admin_Interface**: Active Adminの管理画面インターフェース
- **Data_Package**: エクスポートされたZIPファイル（data.json + storageフォルダを含む）
- **Active_Storage_Blob**: Active Storageで管理される添付ファイルのメタデータ
- **Active_Storage_Attachment**: モデルと添付ファイルの関連付け

## Requirements

### Requirement 1: データエクスポート機能

**User Story:** As a 管理者, I want to 本番環境のデータをエクスポートする, so that 開発環境にデータを移行できる

#### Acceptance Criteria

1. WHEN 管理者がエクスポートボタンをクリックする, THEN THE System SHALL 全対象データをJSON形式でエクスポートする
2. WHEN エクスポートを実行する, THEN THE System SHALL AdminUser、Article、Category、Tag、Section、SectionContent、MyStorySection、Contact、SiteSettingの全レコードを含める
3. WHEN エクスポートを実行する, THEN THE System SHALL Active Storageの添付ファイル（画像など）を全て含める
4. WHEN エクスポートを実行する, THEN THE System SHALL data.jsonとstorageフォルダを含むZIPファイルを生成する
5. WHEN エクスポートが完了する, THEN THE System SHALL ZIPファイルをダウンロード可能にする

### Requirement 2: データインポート機能

**User Story:** As a 管理者, I want to エクスポートしたデータをインポートする, so that 開発環境にデータを復元できる

#### Acceptance Criteria

1. WHEN 管理者がインポートボタンをクリックする, THEN THE System SHALL ZIPファイルのアップロードフォームを表示する
2. WHEN ZIPファイルをアップロードする, THEN THE System SHALL 既存の全データを削除する
3. WHEN 既存データを削除した後, THEN THE System SHALL data.jsonからデータベースレコードを復元する
4. WHEN データベースレコードを復元する, THEN THE System SHALL storageフォルダからActive Storageの添付ファイルを復元する
5. WHEN インポートが完了する, THEN THE System SHALL 成功メッセージを表示する

### Requirement 3: パスワードのリセット

**User Story:** As a 管理者, I want to インポート時にパスワードをリセットする, so that 開発環境で安全にログインできる

#### Acceptance Criteria

1. WHEN AdminUserをインポートする, THEN THE System SHALL 全AdminUserのパスワードを開発環境用のデフォルトパスワードにリセットする
2. WHEN パスワードをリセットする, THEN THE System SHALL encrypted_passwordフィールドを新しいパスワードで上書きする
3. WHEN インポートが完了する, THEN THE System SHALL リセット後のパスワード情報をログに出力する

### Requirement 4: 管理画面インターフェース

**User Story:** As a 管理者, I want to 管理画面からエクスポート/インポートを実行する, so that コマンドラインを使わずに操作できる

#### Acceptance Criteria

1. WHEN 管理画面のダッシュボードを表示する, THEN THE Admin_Interface SHALL エクスポートボタンを表示する
2. WHEN 管理画面のダッシュボードを表示する, THEN THE Admin_Interface SHALL インポートボタンを表示する
3. WHEN エクスポートボタンをクリックする, THEN THE Admin_Interface SHALL エクスポート処理を実行し、ZIPファイルをダウンロードする
4. WHEN インポートボタンをクリックする, THEN THE Admin_Interface SHALL ファイルアップロードフォームを表示する
5. WHEN ZIPファイルをアップロードする, THEN THE Admin_Interface SHALL インポート処理を実行し、完了メッセージを表示する

### Requirement 5: エラーハンドリング

**User Story:** As a 管理者, I want to エラーが発生した際に適切なメッセージを受け取る, so that 問題を把握し対処できる

#### Acceptance Criteria

1. IF 無効なZIPファイルをアップロードする, THEN THE System SHALL エラーメッセージを表示し、インポートを中止する
2. IF data.jsonが存在しないZIPファイルをアップロードする, THEN THE System SHALL エラーメッセージを表示し、インポートを中止する
3. IF インポート中にデータベースエラーが発生する, THEN THE System SHALL トランザクションをロールバックし、エラーメッセージを表示する
4. IF エクスポート中にエラーが発生する, THEN THE System SHALL エラーメッセージを表示し、処理を中止する
5. WHEN エラーが発生する, THEN THE System SHALL エラー詳細をRailsログに記録する

### Requirement 6: データ整合性の保証

**User Story:** As a 管理者, I want to インポート後のデータが整合性を保つ, so that アプリケーションが正常に動作する

#### Acceptance Criteria

1. WHEN データをインポートする, THEN THE System SHALL 関連付け（has_many、belongs_toなど）を正しく復元する
2. WHEN Active Storageを復元する, THEN THE System SHALL active_storage_blobsとactive_storage_attachmentsテーブルを正しく復元する
3. WHEN データをインポートする, THEN THE System SHALL 外部キー制約を満たすようにデータを投入する
4. WHEN インポートが完了する, THEN THE System SHALL 全モデルのバリデーションをパスする
5. WHEN インポートが完了する, THEN THE System SHALL article_count、tag_countなどのカウンターキャッシュを正しく更新する

### Requirement 7: セキュリティとアクセス制御

**User Story:** As a システム管理者, I want to エクスポート/インポート機能を管理者のみに制限する, so that 不正なデータ操作を防ぐ

#### Acceptance Criteria

1. WHEN 非管理者ユーザがエクスポート機能にアクセスする, THEN THE System SHALL アクセスを拒否する
2. WHEN 非管理者ユーザがインポート機能にアクセスする, THEN THE System SHALL アクセスを拒否する
3. WHEN 管理者がエクスポート/インポートを実行する, THEN THE System SHALL 操作ログを記録する
4. THE System SHALL 本番環境でのインポート実行時に確認ダイアログを表示する
5. THE System SHALL エクスポートされたZIPファイルに機密情報（暗号化されたパスワードなど）を含める

### Requirement 8: パフォーマンスと進捗表示

**User Story:** As a 管理者, I want to エクスポート/インポートの進捗を確認する, so that 処理が正常に進行していることを把握できる

#### Acceptance Criteria

1. WHEN 大量のデータをエクスポートする, THEN THE System SHALL バッチ処理で効率的にデータを処理する
2. WHEN エクスポート/インポートを実行する, THEN THE System SHALL 進捗状況をログに出力する
3. WHEN Active Storageファイルをコピーする, THEN THE System SHALL ファイルごとに進捗をログに出力する
4. WHEN インポートを実行する, THEN THE System SHALL トランザクション内で全データを処理する
5. WHEN エクスポート/インポートが完了する, THEN THE System SHALL 処理時間と処理件数をログに出力する
