# Implementation Plan: Database Export/Import

## Overview

管理画面からボタン操作でデータベースとActive Storageをエクスポート/インポートする機能を実装します。エクスポートはZIP形式（data.json + storageフォルダ）で行い、インポート時は既存データをクリアしてから復元します。

## Tasks

- [ ] 1. Setup and Infrastructure
  - ルーティングとコントローラの基本構造を作成
  - 必要なgemの追加（rubyzip）
  - _Requirements: 4.1, 4.2_

- [ ] 2. Implement Export Services
  - [ ] 2.1 Create DatabaseExportService
    - 全対象モデル（AdminUser、Article、Category、Tag、Section、SectionContent、MyStorySection、Contact、SiteSetting）のレコードをJSON化
    - Active Storageメタデータ（blobs、attachments）をエクスポート
    - メタデータ（exported_at、models_count）を生成
    - _Requirements: 1.1, 1.2_

  - [ ]* 2.2 Write property test for DatabaseExportService
    - **Property 1: Export includes all model records**
    - **Validates: Requirements 1.2**

  - [ ] 2.3 Create ActiveStorageExportService
    - storage/ディレクトリ全体を一時ディレクトリにコピー
    - 進捗ログを出力
    - _Requirements: 1.3_

  - [ ]* 2.4 Write property test for ActiveStorageExportService
    - **Property 2: Export includes all Active Storage files**
    - **Validates: Requirements 1.3**

  - [ ] 2.5 Create ZipGeneratorService
    - data.jsonを一時ディレクトリに書き込み
    - 一時ディレクトリの内容をZIPファイルに圧縮
    - 一時ファイルをクリーンアップ
    - _Requirements: 1.4_

  - [ ]* 2.6 Write property test for ZipGeneratorService
    - **Property 3: Export generates valid ZIP structure**
    - **Validates: Requirements 1.4**

- [ ] 3. Implement Export Controller Action
  - [ ] 3.1 Add export action to Admin::DatabaseController
    - サービスクラスを呼び出してZIPファイルを生成
    - ZIPファイルをダウンロードレスポンスとして返す
    - エラーハンドリングとログ記録
    - _Requirements: 1.5, 5.4, 7.3_

  - [ ]* 3.2 Write integration test for export action
    - エクスポートボタンからZIPダウンロードまでの流れをテスト
    - _Requirements: 1.5, 4.3_

- [ ] 4. Checkpoint - Ensure export tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 5. Implement Import Services
  - [ ] 5.1 Create ZipExtractorService
    - ZIPファイルを一時ディレクトリに解凍
    - data.jsonとstorageフォルダの存在を検証
    - 無効なZIPファイルのエラーハンドリング
    - _Requirements: 5.1, 5.2_

  - [ ]* 5.2 Write unit test for ZipExtractorService
    - 無効なZIPファイルのエラーケースをテスト
    - _Requirements: 5.1, 5.2_

  - [ ] 5.3 Create DatabaseImportService
    - トランザクション内で既存データを削除
    - data.jsonからレコードを投入（外部キー制約を考慮した順序）
    - AdminUserのパスワードをリセット
    - カウンターキャッシュ（article_count、tag_count）を更新
    - バリデーションエラーのハンドリング
    - _Requirements: 2.2, 2.3, 3.1, 6.1, 6.4, 6.5_

  - [ ]* 5.4 Write property test for DatabaseImportService - Round trip
    - **Property 4: Import-Export round trip preserves data**
    - **Validates: Requirements 2.2, 2.3, 6.1**

  - [ ]* 5.5 Write property test for DatabaseImportService - Password reset
    - **Property 6: Import resets all admin passwords**
    - **Validates: Requirements 3.1**

  - [ ]* 5.6 Write property test for DatabaseImportService - Validation
    - **Property 8: Import validates all records**
    - **Validates: Requirements 6.4**

  - [ ]* 5.7 Write property test for DatabaseImportService - Counter caches
    - **Property 9: Import updates counter caches correctly**
    - **Validates: Requirements 6.5**

  - [ ]* 5.8 Write property test for DatabaseImportService - Transaction rollback
    - **Property 7: Import transaction rollback on error**
    - **Validates: Requirements 5.3**

  - [ ] 5.9 Create ActiveStorageImportService
    - 解凍されたstorageフォルダからファイルをコピー
    - 既存のstorageフォルダをバックアップ（オプション）
    - 進捗ログを出力
    - _Requirements: 2.4, 6.2_

  - [ ]* 5.10 Write property test for ActiveStorageImportService
    - **Property 5: Import-Export round trip preserves Active Storage**
    - **Validates: Requirements 2.4, 6.2**

- [ ] 6. Implement Import Controller Actions
  - [ ] 6.1 Add import_form action to Admin::DatabaseController
    - インポートフォームを表示
    - 本番環境では確認ダイアログを表示
    - _Requirements: 2.1, 7.4_

  - [ ] 6.2 Add import action to Admin::DatabaseController
    - アップロードされたZIPファイルを受け取る
    - サービスクラスを呼び出してインポート実行
    - 成功/エラーメッセージを表示
    - エラーハンドリングとログ記録
    - _Requirements: 2.5, 5.3, 5.5, 7.3_

  - [ ]* 6.3 Write integration test for import actions
    - インポートフォームからデータ復元までの流れをテスト
    - _Requirements: 2.5, 4.5_

- [ ] 7. Checkpoint - Ensure import tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 8. Add UI Components
  - [ ] 8.1 Add export/import buttons to admin dashboard
    - ダッシュボードビューにエクスポートボタンを追加
    - ダッシュボードビューにインポートボタンを追加
    - _Requirements: 4.1, 4.2_

  - [ ] 8.2 Create import form view
    - ファイルアップロードフォームを作成
    - 本番環境用の確認ダイアログを追加
    - _Requirements: 2.1, 7.4_

  - [ ]* 8.3 Write system test for UI components
    - ボタンの表示とクリック動作をテスト
    - _Requirements: 4.1, 4.2, 4.3, 4.4_

- [ ] 9. Implement Security and Access Control
  - [ ] 9.1 Add authorization checks
    - 非管理者ユーザのアクセスを拒否
    - Punditポリシーを作成（必要に応じて）
    - _Requirements: 7.1, 7.2_

  - [ ]* 9.2 Write unit test for authorization
    - 非管理者ユーザのアクセス拒否をテスト
    - _Requirements: 7.1, 7.2_

  - [ ]* 9.3 Write property test for logging
    - **Property 10: Operations are logged**
    - **Validates: Requirements 5.5, 7.3**

  - [ ]* 9.4 Write property test for encrypted data export
    - **Property 11: Export includes encrypted data**
    - **Validates: Requirements 7.5**

- [ ] 10. Final Integration and Documentation
  - [ ] 10.1 Add comprehensive error handling
    - 全サービスクラスにエラーハンドリングを追加
    - エラーメッセージの日本語化
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_

  - [ ] 10.2 Add progress logging
    - エクスポート/インポートの進捗ログを追加
    - 処理時間と処理件数をログに出力
    - _Requirements: 8.2, 8.3, 8.5_

  - [ ]* 10.3 Write integration test for error scenarios
    - 無効なZIPファイル、data.json欠落などのエラーケースをテスト
    - _Requirements: 5.1, 5.2, 5.3, 5.4_

  - [ ] 10.4 Update README with usage instructions
    - エクスポート/インポート機能の使い方を記載
    - 注意事項（本番環境での使用、パスワードリセットなど）を記載

- [ ] 11. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties
- Unit tests validate specific examples and edge cases
- Integration tests validate end-to-end flows
