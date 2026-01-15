# Markdownサンプルコンテンツ更新スクリプト
puts "🔄 Updating articles with Markdown content..."

# Rails記事の更新
rails_article = Article.find_by(slug: 'rails-8-1-new-features')
if rails_article
  rails_article.update!(
    content: <<~MARKDOWN
      # Rails 8.1の新機能まとめ

      Rails 8.1では、多くの**新機能**が追加されました。特に注目すべきは以下の点です：

      ## 主要な新機能

      ### Solid Queue
      新しいジョブキューシステムで、Redisに依存せずにバックグラウンド処理を実行できます。

      ```ruby
      # Solid Queueの基本設定例
      class MyJob < ApplicationJob
        def perform(user)
          UserMailer.welcome(user).deliver_now
        end
      end
      ```

      ### Solid Cache
      アプリケーションキャッシュをSQLiteやPostgreSQLで管理できる新機能です。

      - **高速アクセス**: SQLite/PostgreSQLベースの高速キャッシュ
      - **永続化**: サーバー再起動後もキャッシュが保持される
      - **柔軟な設定**: プロジェクトに応じたカスタマイズ可能

      ### Solid Cable
      ActionCableの代替として、データベースベースのWebSocket接続を提供します。

      > Solid Cableは、Redis不要でリアルタイム機能を実装できる革新的な機能です。

      ## 導入のメリット

      1. **インフラの簡素化**
      2. **運用コストの削減**
      3. **開発効率の向上**

      詳細な情報は[Rails公式ドキュメント](https://guides.rubyonrails.org/)をご確認ください。
    MARKDOWN
  )
  puts "✅ Rails記事をMarkdown形式で更新しました"
end

# Docker記事の更新
docker_article = Article.find_by(slug: 'rails-docker-development')
if docker_article
  docker_article.update!(
    content: <<~MARKDOWN
      # Docker環境でのRails開発効率化

      Docker環境での Rails開発における効率化のポイントを解説します。

      ## なぜDockerを使うのか

      開発環境の統一、依存関係の管理、本番環境との差異を最小限にするために、Dockerは非常に有効です。

      ### メリット
      - **環境統一**: チーム全員が同じ環境で開発可能
      - **依存関係管理**: OS固有の問題を解決
      - **デプロイ**: 本番環境への展開が簡単

      ## docker-compose.ymlの設定

      ```yaml
      services:
        db:
          image: postgres:17-alpine
          environment:
            POSTGRES_DB: myapp_development
            POSTGRES_USER: myapp
            POSTGRES_PASSWORD: password
        web:
          build: .
          command: bundle exec rails server -b 0.0.0.0
          volumes:
            - .:/app
          ports:
            - "3000:3000"
          depends_on:
            - db
      ```

      ## ベストプラクティス

      ### 1. Alpine Linuxベースのイメージを使用
      軽量で高速な起動が可能です。

      ### 2. マルチステージビルドで軽量化
      ```dockerfile
      FROM ruby:3.4-alpine as builder
      # ビルド用の依存関係インストール

      FROM ruby:3.4-alpine
      # 実行時の最小限の依存関係のみ
      ```

      ### 3. 開発用と本番用でDockerfileを分ける
      環境に応じた最適化が可能です。

      > **重要**: `.dockerignore`を適切に設定して、ビルド時間を短縮しましょう。

      ## トラブルシューティング

      | 問題 | 解決方法 |
      |------|---------|
      | ファイル変更が反映されない | volumeマウントの設定確認 |
      | 起動が遅い | Alpine Linuxイメージの使用 |
      | 権限エラー | ユーザーIDの適切な設定 |

      詳細な設定方法については、プロジェクトの`docker-compose.yml`をご参照ください。
    MARKDOWN
  )
  puts "✅ Docker記事をMarkdown形式で更新しました"
end

# Works記事の更新
works_article = Article.find_by(slug: 'ec-site-renewal')
if works_article
  works_article.update!(
    content: <<~MARKDOWN
      # ECサイトリニューアルプロジェクト

      大手ECサイトのフルリニューアルプロジェクトを担当。Rails + React + AWSで構築しました。

      ## プロジェクト概要

      - **期間**: 6ヶ月
      - **規模**: 開発メンバー15名
      - **技術スタック**: Ruby on Rails, React, AWS, PostgreSQL

      ## 課題と解決策

      ### 既存システムの課題
      1. **パフォーマンス**: 大量のアクセスに対応できない
      2. **運用性**: 管理機能の不足
      3. **拡張性**: 新機能追加が困難

      ### 解決アプローチ
      ```ruby
      # 高速化のためのキャッシュ戦略
      class ProductsController < ApplicationController
        before_action :set_cache_headers
      #{'  '}
        def index
          page = params[:page] || 1
          @products = Rails.cache.fetch("products_\#{page}", expires_in: 1.hour) do
            Product.includes(:categories).page(page)
          end
        end
      end
      ```

      ## 技術的なハイライト

      ### フロントエンド
      - **React 18**: 最新のHooksベースのアーキテクチャ
      - **TypeScript**: 型安全性の確保
      - **Next.js**: SSRによるSEO最適化

      ### バックエンド
      - **Rails 7 API**: RESTfulな設計
      - **PostgreSQL**: 高性能なデータベース
      - **Sidekiq**: 非同期処理

      ### インフラ
      - **AWS ECS**: コンテナオーケストレーション
      - **CloudFront**: CDNによる高速化
      - **RDS**: マネージドデータベース

      ## 成果

      | 指標 | 改善前 | 改善後 | 改善率 |
      |------|-------|-------|-------|
      | ページ表示速度 | 3.2秒 | 1.1秒 | **65%改善** |
      | 同時接続数 | 100 | 1,000 | **10倍向上** |
      | 管理工数 | 40h/月 | 10h/月 | **75%削減** |

      > このプロジェクトでは、ユーザー体験の向上と運用効率化を両立することができました。

      ## 今後の展望

      - **AI活用**: レコメンデーション機能の強化
      - **モバイル対応**: PWAの導入検討
      - **国際化**: 多言語対応の実装

      詳細な技術資料は[GitHub](https://github.com/miyakawa2449/ec-site-project)をご参照ください。
    MARKDOWN
  )
  puts "✅ ECサイト記事をMarkdown形式で更新しました"
end

puts "🚀 Markdown content update completed!"
