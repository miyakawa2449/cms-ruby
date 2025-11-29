class Api::V1::BaseController < Api::BaseController
  # API v1用の基本コントローラー
  # API v1固有の設定と機能を提供
  
  before_action :set_api_v1_settings
  
  protected
  
  def set_api_v1_settings
    @api_version = 'v1'
    @api_settings = {
      max_per_page: 100,
      default_per_page: 25,
      max_include_depth: 3,
      supported_formats: %w[json]
    }
  end
  
  # API v1用のページネーション処理
  def paginate_collection(collection, options = {})
    per_page = determine_per_page(params[:per_page], options[:per_page])
    page = determine_page(params[:page])
    
    collection.page(page).per(per_page)
  end
  
  # API v1用のフィルタリング処理
  def apply_filters(collection, allowed_filters = {})
    filtered = collection
    
    allowed_filters.each do |param_name, filter_config|
      next unless params[param_name].present?
      
      case filter_config[:type]
      when :exact
        filtered = filtered.where(filter_config[:column] => params[param_name])
      when :like
        filtered = filtered.where("#{filter_config[:column]} ILIKE ?", "%#{params[param_name]}%")
      when :in
        values = params[param_name].split(',').map(&:strip)
        filtered = filtered.where(filter_config[:column] => values)
      when :date_range
        if params[param_name].include?('..')
          start_date, end_date = params[param_name].split('..').map(&:strip)
          filtered = filtered.where(filter_config[:column] => start_date..end_date)
        end
      when :custom
        filtered = filter_config[:proc].call(filtered, params[param_name])
      end
    end
    
    filtered
  end
  
  # API v1用のソート処理
  def apply_sorting(collection, allowed_sorts = [], default_sort = nil)
    sort_param = params[:sort] || default_sort
    return collection unless sort_param.present?
    
    # ソート指定の解析 (例: "created_at:desc", "title:asc")
    sort_parts = sort_param.split(':')
    sort_column = sort_parts[0]
    sort_direction = sort_parts[1]&.downcase || 'asc'
    
    # 許可されたソート列のチェック
    return collection unless allowed_sorts.include?(sort_column.to_sym)
    return collection unless %w[asc desc].include?(sort_direction)
    
    collection.order("#{sort_column} #{sort_direction}")
  end
  
  # API v1用のインクルード処理（関連テーブルの取得）
  def apply_includes(collection, allowed_includes = {})
    return collection unless params[:include].present?
    
    requested_includes = params[:include].split(',').map(&:strip).map(&:to_sym)
    safe_includes = requested_includes & allowed_includes.keys
    
    return collection if safe_includes.empty?
    
    includes_hash = {}
    safe_includes.each do |include_name|
      includes_hash[include_name] = allowed_includes[include_name]
    end
    
    collection.includes(includes_hash)
  end
  
  # API v1用のフィールド選択処理
  def apply_field_selection(data, allowed_fields = nil)
    return data unless params[:fields].present? && allowed_fields.present?
    
    requested_fields = params[:fields].split(',').map(&:strip).map(&:to_sym)
    safe_fields = requested_fields & allowed_fields
    
    return data if safe_fields.empty?
    
    case data
    when Array
      data.map { |item| item.slice(*safe_fields) }
    when Hash
      data.slice(*safe_fields)
    else
      data
    end
  end
  
  # API v1用の検索処理
  def apply_search(collection, search_fields = [])
    query = params[:q] || params[:search]
    return collection unless query.present? && search_fields.any?
    
    # PostgreSQL全文検索（Phase 2Bで実装予定）
    if collection.column_names.include?('search_vector')
      collection.where("search_vector @@ plainto_tsquery('japanese', ?)", query)
    else
      # フォールバック: ILIKE検索
      conditions = search_fields.map { |field| "#{field} ILIKE ?" }.join(' OR ')
      values = Array.new(search_fields.length, "%#{query}%")
      collection.where(conditions, *values)
    end
  end
  
  # API v1用のレスポンス構築
  def build_collection_response(collection, serializer_class = nil, options = {})
    # シリアライザーが指定されている場合は使用
    if serializer_class
      serialized_data = collection.map { |item| serializer_class.new(item, options).as_json }
    else
      serialized_data = collection.as_json(options)
    end
    
    {
      data: serialized_data,
      meta: pagination_meta(collection).merge(
        count: serialized_data.length,
        total_count: collection.respond_to?(:total_count) ? collection.total_count : serialized_data.length
      )
    }
  end
  
  def build_resource_response(resource, serializer_class = nil, options = {})
    if serializer_class
      { data: serializer_class.new(resource, options).as_json }
    else
      { data: resource.as_json(options) }
    end
  end
  
  private
  
  def determine_per_page(requested_per_page, default_per_page = nil)
    per_page = (requested_per_page || default_per_page || @api_settings[:default_per_page]).to_i
    
    # 範囲チェック
    if per_page < 1
      @api_settings[:default_per_page]
    elsif per_page > @api_settings[:max_per_page]
      @api_settings[:max_per_page]
    else
      per_page
    end
  end
  
  def determine_page(requested_page)
    page = (requested_page || 1).to_i
    page < 1 ? 1 : page
  end
  
  # API v1用のエラーメッセージ
  def render_v1_validation_error(errors)
    render_error(
      'Validation failed',
      format_validation_errors(errors),
      :unprocessable_entity,
      'VALIDATION_ERROR'
    )
  end
  
  def format_validation_errors(errors)
    case errors
    when ActiveModel::Errors
      errors.full_messages.map do |message|
        field = errors.keys.find { |key| errors[key].any? } || 'base'
        {
          field: field,
          message: message,
          code: infer_error_code(message)
        }
      end
    when Array
      errors.map { |error| { message: error } }
    when String
      [{ message: errors }]
    else
      [{ message: 'Unknown validation error' }]
    end
  end
  
  def infer_error_code(message)
    case message.downcase
    when /can't be blank/, /is required/
      'REQUIRED'
    when /has already been taken/
      'ALREADY_EXISTS'
    when /is too short/
      'TOO_SHORT'
    when /is too long/
      'TOO_LONG'
    when /is not a number/
      'INVALID_NUMBER'
    when /is not included in the list/
      'INVALID_CHOICE'
    else
      'INVALID'
    end
  end
end