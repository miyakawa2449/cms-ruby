class PortfolioController < ApplicationController
  # ポートフォリオページのメインコントローラー
  # 8セクション構成の縦スクロール型ページを制御
  
  before_action :set_portfolio_data, only: [:show, :index]
  before_action :track_page_view, only: [:show, :index]
  
  def index
    # トップページ（ポートフォリオ全体表示）
    @page_title = 'ポートフォリオ'
    @page_description = 'シニアエンジニアとしての技術スキル、経験、実績を紹介するポートフォリオサイトです。'
    
    # セクションデータの準備（Phase 2Bで実装）
    # @sections = PortfolioSection.active.ordered.includes(:contents)
    @sections = mock_sections_data
  end
  
  def show
    # 個別セクション詳細ページ
    section_key = params[:section]
    
    # セクションが存在するかチェック
    unless valid_section?(section_key)
      render_not_found and return
    end
    
    # @section = PortfolioSection.find_by(key: section_key, active: true)
    # render_not_found and return unless @section
    
    @section = mock_section_data(section_key)
    @page_title = "#{@section[:title]} | ポートフォリオ"
    @page_description = @section[:description]
  end
  
  def contact
    # お問い合わせフォーム
    @contact = ContactForm.new
    @page_title = 'お問い合わせ'
    @page_description = 'ご質問、ご依頼、ご相談などお気軽にお問い合わせください。'
  end
  
  def create_contact
    # お問い合わせフォーム送信処理
    @contact = ContactForm.new(contact_params)
    
    if @contact.valid?
      # Phase 2Bでメール送信機能を実装
      # ContactMailer.new_inquiry(@contact).deliver_later
      # NotificationJob.perform_async('contact', @contact.to_h)
      
      flash[:notice] = 'お問い合わせありがとうございます。内容を確認の上、ご返信いたします。'
      redirect_to contact_path
    else
      @page_title = 'お問い合わせ'
      render :contact, status: :unprocessable_entity
    end
  end
  
  private
  
  def set_portfolio_data
    # 共通データの設定
    @site_title = 'Portfolio Site'
    @site_description = 'Senior Engineer Portfolio & Technical Blog'
    
    # Navigation用データ（Phase 2Bで実装）
    # @nav_sections = PortfolioSection.active.ordered.pluck(:key, :title)
    @nav_sections = [
      ['hero', 'Hero'],
      ['about', 'About'],
      ['skills', 'Skills'],
      ['experience', 'Experience'],
      ['projects', 'Projects'],
      ['achievements', 'Achievements'],
      ['contact', 'Contact'],
      ['blog', 'Blog']
    ]
  end
  
  def track_page_view
    # ページビューの追跡（Phase 2Bで実装）
    # PageViewJob.perform_async(request_tracking_data)
    Rails.logger.info "Portfolio page view: #{action_name} from #{request.remote_ip}"
  end
  
  def valid_section?(section_key)
    valid_sections = %w[hero about skills experience projects achievements contact blog]
    valid_sections.include?(section_key)
  end
  
  def mock_sections_data
    # Phase 2Bまでの仮データ
    [
      {
        key: 'hero',
        title: 'Hero Section',
        description: 'メインビジュアルとキャッチコピー',
        active: true,
        sort_order: 1
      },
      {
        key: 'about',
        title: 'About Me',
        description: '自己紹介とプロフィール',
        active: true,
        sort_order: 2
      },
      {
        key: 'skills',
        title: 'Technical Skills',
        description: '技術スキルとツール',
        active: true,
        sort_order: 3
      },
      {
        key: 'experience',
        title: 'Work Experience',
        description: '職歴と経験',
        active: true,
        sort_order: 4
      },
      {
        key: 'projects',
        title: 'Projects',
        description: 'プロジェクト実績',
        active: true,
        sort_order: 5
      },
      {
        key: 'achievements',
        title: 'Achievements',
        description: '実績と成果',
        active: true,
        sort_order: 6
      },
      {
        key: 'contact',
        title: 'Contact',
        description: 'お問い合わせ',
        active: true,
        sort_order: 7
      },
      {
        key: 'blog',
        title: 'Technical Blog',
        description: '技術ブログ',
        active: true,
        sort_order: 8
      }
    ]
  end
  
  def mock_section_data(section_key)
    mock_sections_data.find { |section| section[:key] == section_key } || {}
  end
  
  def contact_params
    params.require(:contact_form).permit(:name, :email, :subject, :message, :company, :phone)
  end
  
  def request_tracking_data
    {
      path: request.path,
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      referer: request.referer,
      timestamp: Time.current,
      session_id: request.session.id
    }
  end
end