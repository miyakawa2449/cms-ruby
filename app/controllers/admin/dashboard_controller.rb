class Admin::DashboardController < Admin::BaseController
  # 管理画面ダッシュボードコントローラー
  # システム全体の統計情報と最近の活動を表示
  
  def index
    # ダッシュボードメインページ
    @page_title = 'ダッシュボード'
    
    # 統計データの取得
    load_dashboard_statistics
    load_recent_activities
    load_system_status
    load_quick_actions
  end
  
  def analytics
    # アナリティクス詳細ページ
    @page_title = 'アナリティクス'
    @date_range = parse_date_range
    
    load_analytics_data(@date_range)
    load_traffic_data(@date_range)
    load_content_performance(@date_range)
  end
  
  def system_health
    # システム健全性チェック
    @page_title = 'システムヘルス'
    
    @health_checks = perform_health_checks
    @system_info = collect_system_info
    @database_info = collect_database_info
    @storage_info = collect_storage_info
    
    respond_to do |format|
      format.html
      format.json { render json: { health_checks: @health_checks, status: overall_health_status } }
    end
  end
  
  private
  
  def load_dashboard_statistics
    # Phase 2Bで実装予定のダッシュボード統計
    @statistics = {
      content: {
        total_articles: 0, # Article.count
        published_articles: 0, # Article.published.count
        draft_articles: 0, # Article.draft.count
        total_categories: 0, # Category.count
        total_tags: 0, # Tag.count
        portfolio_sections: 8 # PortfolioSection.count
      },
      engagement: {
        total_views: 0, # Article.sum(:views_count)
        monthly_views: 0, # 今月のビュー数
        weekly_views: 0, # 今週のビュー数
        daily_views: 0, # 今日のビュー数
        total_comments: 0, # Comment.approved.count
        pending_comments: 0, # Comment.pending.count
        spam_comments: 0 # Comment.spam.count
      },
      media: {
        total_files: 0, # MediaFile.count
        storage_used_mb: 0, # MediaFile.sum(:file_size) / (1024 * 1024)
        images_count: 0, # MediaFile.where(content_type: /^image/).count
        documents_count: 0 # MediaFile.where.not(content_type: /^image/).count
      },
      system: {
        admin_users: 1, # AdminUser.count
        active_sessions: 0, # アクティブセッション数
        last_backup: 'Never', # Backup.completed.last&.completed_at
        cache_hit_rate: 0, # キャッシュヒット率
        average_response_time: 0 # 平均レスポンス時間（ms）
      }
    }
  end
  
  def load_recent_activities
    # 最近の活動（Phase 2Bで実装）
    @recent_activities = [
      # {
      #   type: 'article',
      #   action: 'published',
      #   title: 'New article published',
      #   description: 'Rails 8.0の新機能解説',
      #   timestamp: 2.hours.ago,
      #   user: current_admin_user.name,
      #   icon: 'article'
      # }
    ]
    
    # モックデータ（Phase 2A用）
    @recent_activities = [
      {
        type: 'system',
        action: 'setup',
        title: 'システム初期化完了',
        description: 'Phase 2A環境構築が完了しました',
        timestamp: Time.current,
        user: 'System',
        icon: 'setup'
      }
    ]
  end
  
  def load_system_status
    # システムステータス
    @system_status = {
      database: check_database_connection,
      cache: check_cache_connection,
      storage: check_storage_availability,
      background_jobs: check_background_jobs,
      external_apis: check_external_apis
    }
  end
  
  def load_quick_actions
    # クイックアクション
    @quick_actions = [
      {
        title: '新しい記事を作成',
        description: 'ブログ記事を新規作成',
        path: new_admin_article_path,
        icon: 'plus',
        color: 'blue'
      },
      {
        title: 'メディアをアップロード',
        description: '画像やファイルをアップロード',
        path: new_admin_media_file_path,
        icon: 'upload',
        color: 'green'
      },
      {
        title: 'コメントを確認',
        description: '承認待ちコメントを確認',
        path: admin_comments_path(status: 'pending'),
        icon: 'message',
        color: 'yellow',
        badge: @statistics[:engagement][:pending_comments]
      },
      {
        title: 'バックアップを実行',
        description: 'データベースのバックアップ実行',
        path: admin_backups_path,
        icon: 'backup',
        color: 'purple'
      },
      {
        title: '設定を管理',
        description: 'サイト設定の編集',
        path: admin_settings_path,
        icon: 'settings',
        color: 'gray'
      }
    ]
  end
  
  def load_analytics_data(date_range)
    # アナリティクスデータ（Phase 2Bで実装）
    @analytics_data = {
      page_views: generate_mock_chart_data(date_range, 'views'),
      unique_visitors: generate_mock_chart_data(date_range, 'visitors'),
      bounce_rate: generate_mock_chart_data(date_range, 'bounce_rate'),
      session_duration: generate_mock_chart_data(date_range, 'session_duration')
    }
  end
  
  def load_traffic_data(date_range)
    # トラフィックデータ
    @traffic_data = {
      referrers: [
        { source: 'google.com', visits: 150, percentage: 45 },
        { source: 'twitter.com', visits: 80, percentage: 24 },
        { source: 'github.com', visits: 60, percentage: 18 },
        { source: 'direct', visits: 43, percentage: 13 }
      ],
      devices: [
        { device: 'Desktop', visits: 200, percentage: 60 },
        { device: 'Mobile', visits: 100, percentage: 30 },
        { device: 'Tablet', visits: 33, percentage: 10 }
      ],
      browsers: [
        { browser: 'Chrome', visits: 250, percentage: 75 },
        { browser: 'Safari', visits: 50, percentage: 15 },
        { browser: 'Firefox', visits: 33, percentage: 10 }
      ]
    }
  end
  
  def load_content_performance(date_range)
    # コンテンツパフォーマンス
    @content_performance = {
      popular_articles: [
        { title: 'Rails 8.0の新機能解説', views: 156, path: '/blog/rails-8-new-features' },
        { title: 'PostgreSQL全文検索の実装', views: 134, path: '/blog/postgresql-full-text-search' },
        { title: 'Docker環境でのRails開発', views: 112, path: '/blog/rails-development-with-docker' }
      ],
      popular_categories: [
        { name: 'Rails', articles: 15, views: 450 },
        { name: 'PostgreSQL', articles: 8, views: 280 },
        { name: 'Docker', articles: 12, views: 320 }
      ]
    }
  end
  
  def perform_health_checks
    # システム健全性チェック
    checks = []
    
    # データベース接続チェック
    checks << {
      name: 'Database Connection',
      status: check_database_connection,
      message: check_database_connection ? 'Connected' : 'Connection failed',
      category: 'database'
    }
    
    # ストレージチェック
    checks << {
      name: 'Storage Available',
      status: check_storage_availability,
      message: check_storage_availability ? 'Available' : 'Storage issues detected',
      category: 'storage'
    }
    
    # メモリ使用量チェック
    memory_usage = get_memory_usage_percentage
    checks << {
      name: 'Memory Usage',
      status: memory_usage < 80,
      message: "#{memory_usage.round(1)}% used",
      category: 'system'
    }
    
    checks
  end
  
  def collect_system_info
    # システム情報の収集
    {
      ruby_version: RUBY_VERSION,
      rails_version: Rails.version,
      environment: Rails.env,
      uptime: get_system_uptime,
      load_average: get_load_average
    }
  end
  
  def collect_database_info
    # データベース情報
    {
      version: get_database_version,
      size: get_database_size,
      connection_count: get_active_connections_count
    }
  end
  
  def collect_storage_info
    # ストレージ情報
    {
      total_space: get_total_disk_space,
      used_space: get_used_disk_space,
      free_space: get_free_disk_space,
      usage_percentage: get_disk_usage_percentage
    }
  end
  
  # Helper methods for system checks
  def check_database_connection
    ActiveRecord::Base.connection.active?
  rescue
    false
  end
  
  def check_cache_connection
    Rails.cache.exist?('health_check') || Rails.cache.write('health_check', 'ok', expires_in: 1.minute)
  rescue
    false
  end
  
  def check_storage_availability
    get_disk_usage_percentage < 90
  end
  
  def check_background_jobs
    # Phase 2BでSidekiqチェックを実装
    true
  end
  
  def check_external_apis
    # Phase 2BでOpenAI APIなどのチェックを実装
    true
  end
  
  def overall_health_status
    @health_checks.all? { |check| check[:status] } ? 'healthy' : 'warning'
  end
  
  def parse_date_range
    case params[:range]
    when 'today'
      Date.current.beginning_of_day..Date.current.end_of_day
    when 'week'
      1.week.ago.beginning_of_day..Time.current
    when 'month'
      1.month.ago.beginning_of_day..Time.current
    else
      7.days.ago.beginning_of_day..Time.current
    end
  end
  
  def generate_mock_chart_data(date_range, data_type)
    # Phase 2A用のモックデータ
    data = []
    date_range.each_day do |day|
      value = case data_type
              when 'views'
                rand(10..100)
              when 'visitors'
                rand(5..50)
              when 'bounce_rate'
                rand(30..70)
              when 'session_duration'
                rand(60..300)
              end
      data << { date: day.strftime('%Y-%m-%d'), value: value }
    end
    data
  end
  
  def get_memory_usage_percentage
    # 簡易的なメモリ使用量取得
    return 0 unless File.exist?('/proc/meminfo')
    
    meminfo = File.read('/proc/meminfo')
    total = meminfo.match(/MemTotal:\s+(\d+)/)[1].to_f
    available = meminfo.match(/MemAvailable:\s+(\d+)/)[1].to_f
    used = total - available
    (used / total) * 100
  rescue
    50 # フォールバック値
  end
  
  def get_system_uptime
    return 'N/A' unless File.exist?('/proc/uptime')
    
    uptime_seconds = File.read('/proc/uptime').split.first.to_f
    days = (uptime_seconds / 86400).to_i
    hours = ((uptime_seconds % 86400) / 3600).to_i
    "#{days}d #{hours}h"
  rescue
    'N/A'
  end
  
  def get_load_average
    return 'N/A' unless File.exist?('/proc/loadavg')
    
    File.read('/proc/loadavg').split[0..2].join(', ')
  rescue
    'N/A'
  end
  
  def get_database_version
    ActiveRecord::Base.connection.execute('SELECT version()').first['version']
  rescue
    'Unknown'
  end
  
  def get_database_size
    result = ActiveRecord::Base.connection.execute(
      "SELECT pg_size_pretty(pg_database_size(current_database()))"
    )
    result.first['pg_size_pretty']
  rescue
    'Unknown'
  end
  
  def get_active_connections_count
    ActiveRecord::Base.connection_pool.connections.count
  rescue
    0
  end
  
  def get_total_disk_space
    stat = `df -h #{Rails.root}`.split("\n")[1].split
    stat[1]
  rescue
    'N/A'
  end
  
  def get_used_disk_space
    stat = `df -h #{Rails.root}`.split("\n")[1].split
    stat[2]
  rescue
    'N/A'
  end
  
  def get_free_disk_space
    stat = `df -h #{Rails.root}`.split("\n")[1].split
    stat[3]
  rescue
    'N/A'
  end
  
  def get_disk_usage_percentage
    stat = `df #{Rails.root}`.split("\n")[1].split
    stat[4].to_i
  rescue
    0
  end
end