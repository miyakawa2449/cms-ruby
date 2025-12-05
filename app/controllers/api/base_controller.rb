class Api::BaseController < ApplicationController
  # CSRFトークンの検証をスキップ（API専用）
  protect_from_forgery with: :null_session
  
  # レスポンス形式の統一
  rescue_from StandardError, with: :handle_internal_error
  rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
  rescue_from ActionController::ParameterMissing, with: :handle_bad_request
  
  private
  
  # 成功レスポンスの構造化
  def render_success(data = nil, status: :ok, meta: {})
    response_data = {
      status: 'success',
      meta: default_meta.merge(meta)
    }
    
    response_data[:data] = data if data
    
    render json: response_data, status: status
  end
  
  # エラーレスポンスの構造化
  def render_error(message, code: nil, status: :unprocessable_entity, details: nil)
    error_data = {
      status: 'error',
      error: {
        message: message,
        code: code || status.to_s.upcase
      },
      meta: default_meta
    }
    
    error_data[:error][:details] = details if details
    
    render json: error_data, status: status
  end
  
  # ページネーション付きレスポンス
  def render_paginated(collection, serializer = nil, status: :ok)
    data = if serializer
             collection.map { |item| serializer.new(item).serializable_hash }
           else
             collection.as_json
           end
    
    meta = {
      pagination: {
        current_page: collection.current_page,
        total_pages: collection.total_pages,
        total_count: collection.total_count,
        per_page: collection.limit_value
      }
    }
    
    render_success(data, status: status, meta: meta)
  end
  
  # デフォルトメタ情報
  def default_meta
    {
      timestamp: Time.current.iso8601,
      version: '1.0'
    }
  end
  
  # エラーハンドラー
  def handle_not_found(exception)
    render_error(
      'リソースが見つかりません',
      code: 'RESOURCE_NOT_FOUND',
      status: :not_found
    )
  end
  
  def handle_bad_request(exception)
    render_error(
      'リクエストパラメータに問題があります',
      code: 'BAD_REQUEST',
      status: :bad_request,
      details: { missing_parameter: exception.param }
    )
  end
  
  def handle_internal_error(exception)
    Rails.logger.error "API Error: #{exception.class} - #{exception.message}"
    Rails.logger.error exception.backtrace.join("\n")
    
    render_error(
      'サーバーエラーが発生しました',
      code: 'INTERNAL_SERVER_ERROR',
      status: :internal_server_error
    )
  end
end