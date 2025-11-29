class Admin::BaseController < ApplicationController
  # 管理画面の基本コントローラー
  # すべての管理画面コントローラーの親クラス
  
  layout 'admin'
  
  # 認証が必要
  before_action :authenticate_admin_user!
  before_action :set_admin_layout_data
  before_action :check_admin_permissions
  before_action :log_admin_access
  
  # CSRFトークンは管理画面では必須
  protect_from_forgery with: :exception
  
  protected
  
  def authenticate_admin_user!
    unless admin_signed_in?
      store_admin_location
      
      if api_request?
        render json: { 
          error: 'Authentication required',
          message: 'Admin authentication is required to access this resource'
        }, status: :unauthorized
      else
        flash[:alert] = 'ログインが必要です'
        redirect_to admin_new_admin_user_session_path
      end
      return false
    end
    
    # セッション更新（Phase 2Bで実装）
    # update_admin_session_activity
  end
  
  def check_admin_permissions
    # 権限チェック（Phase 2Bで詳細実装）
    # unless current_admin_user.has_permission?(controller_name, action_name)
    #   render_admin_forbidden and return false
    # end
    
    return true # Phase 2Aでは全管理者に全権限を付与
  end
  
  def set_admin_layout_data
    # 管理画面レイアウト用の共通データ設定
    @admin_user = current_admin_user
    @admin_navigation = build_admin_navigation
    @admin_breadcrumbs = build_admin_breadcrumbs
    @admin_notifications = fetch_admin_notifications
    @admin_stats = fetch_admin_dashboard_stats if action_name == 'index' && controller_name == 'dashboard'
  end
  
  def log_admin_access
    # 管理者アクセスのログ記録
    return unless Rails.env.production?
    
    Rails.logger.info "Admin Access: #{current_admin_user&.email} - #{controller_name}##{action_name}"
    
    # Phase 2Bで詳細ログを実装
    # AdminAccessLogJob.perform_async(admin_access_log_data)
  end
  
  def store_admin_location
    # リダイレクト後に元のページに戻るための場所を保存
    if request.get? && !request.xhr? && !api_request?
      session[:admin_return_to] = request.fullpath
    end
  end
  
  def redirect_back_or_admin_root
    # 保存されたロケーションまたは管理画面ルートにリダイレクト
    redirect_to(session.delete(:admin_return_to) || admin_root_path)
  end
  
  def render_admin_forbidden
    @error_title = 'アクセス権限がありません'
    @error_message = 'この操作を実行する権限がありません。管理者にお問い合わせください。'
    
    if api_request?
      render json: {
        error: 'Forbidden',
        message: @error_message
      }, status: :forbidden
    else
      render 'admin/shared/forbidden', status: :forbidden
    end
  end
  
  def render_admin_not_found
    @error_title = 'ページが見つかりません'
    @error_message = '指定されたリソースが見つかりませんでした。'
    
    if api_request?
      render json: {
        error: 'Not found',
        message: @error_message
      }, status: :not_found
    else
      render 'admin/shared/not_found', status: :not_found
    end
  end
  
  private
  
  def build_admin_navigation
    # 管理画面ナビゲーションの構築
    [
      {
        title: 'ダッシュボード',
        path: admin_root_path,
        icon: 'dashboard',
        active: controller_name == 'dashboard'
      },
      {
        title: 'ポートフォリオ',
        path: admin_portfolio_sections_path,
        icon: 'portfolio',
        active: controller_name == 'portfolio_sections',
        children: [
          { title: 'セクション管理', path: admin_portfolio_sections_path },
          { title: 'コンテンツ管理', path: admin_section_contents_path }
        ]
      },
      {
        title: 'ブログ',
        path: admin_articles_path,
        icon: 'blog',
        active: %w[articles categories tags comments].include?(controller_name),
        children: [
          { title: '記事管理', path: admin_articles_path },
          { title: 'カテゴリ管理', path: admin_categories_path },
          { title: 'タグ管理', path: admin_tags_path },
          { title: 'コメント管理', path: admin_comments_path }
        ]
      },
      {
        title: 'メディア',
        path: admin_media_files_path,
        icon: 'media',
        active: controller_name == 'media_files'
      },
      {
        title: 'システム',
        path: admin_settings_path,
        icon: 'settings',
        active: %w[settings backups admin_users audit_logs].include?(controller_name),
        children: [
          { title: '設定管理', path: admin_settings_path },
          { title: 'バックアップ', path: admin_backups_path },
          { title: '管理者管理', path: admin_admin_users_path },
          { title: '監査ログ', path: admin_audit_logs_path }
        ]
      }
    ]
  end
  
  def build_admin_breadcrumbs
    breadcrumbs = [{ title: 'ダッシュボード', path: admin_root_path }]
    
    case controller_name
    when 'articles'
      breadcrumbs << { title: 'ブログ管理', path: admin_articles_path }
      breadcrumbs << { title: '記事一覧', path: admin_articles_path } unless action_name == 'index'
    when 'categories'
      breadcrumbs << { title: 'ブログ管理', path: admin_articles_path }
      breadcrumbs << { title: 'カテゴリ管理', path: admin_categories_path }
    when 'portfolio_sections'
      breadcrumbs << { title: 'ポートフォリオ管理', path: admin_portfolio_sections_path }
    when 'settings'
      breadcrumbs << { title: 'システム管理', path: admin_settings_path }
    end
    
    breadcrumbs
  end
  
  def fetch_admin_notifications
    # 管理者向け通知の取得（Phase 2Bで実装）
    # AdminNotification.unread.for_user(current_admin_user).limit(5)
    []
  end
  
  def fetch_admin_dashboard_stats
    # ダッシュボード統計情報（Phase 2Bで実装）
    {
      articles_count: 0, # Article.count
      published_articles: 0, # Article.published.count
      draft_articles: 0, # Article.draft.count
      comments_pending: 0, # Comment.pending.count
      media_files_count: 0, # MediaFile.count
      total_views: 0, # Article.sum(:views_count)
      monthly_views: 0, # 今月のビュー数
      storage_usage: 0 # ストレージ使用量（MB）
    }
  end
  
  def admin_access_log_data
    {
      admin_user_id: current_admin_user&.id,
      controller: controller_name,
      action: action_name,
      path: request.path,
      method: request.method,
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      timestamp: Time.current,
      session_id: request.session.id
    }
  end
  
  def update_admin_session_activity
    # セッションアクティビティの更新（Phase 2Bで実装）
    # current_admin_user.update(last_activity_at: Time.current)
  end
end