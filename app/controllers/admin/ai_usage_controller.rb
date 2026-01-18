# AI usage statistics dashboard controller
# Displays usage metrics, costs, and provides CSV export
class Admin::AiUsageController < Admin::BaseController
  # GET /admin/ai_usage
  def index
    @summary = Ai::UsageStatisticsService.dashboard_summary
    @chart_data = Ai::UsageStatisticsService.chart_data(days: 30)

    # Date range for filtering (defaults to current month)
    @start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : Date.current.beginning_of_month
    @end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : Date.current

    @usage_by_feature = Ai::UsageStatisticsService.usage_by_feature(@start_date, @end_date)
    @model_breakdown = Ai::UsageStatisticsService.model_breakdown(@start_date, @end_date)
  rescue Date::Error
    @start_date = Date.current.beginning_of_month
    @end_date = Date.current
    @usage_by_feature = Ai::UsageStatisticsService.usage_by_feature(@start_date, @end_date)
    @model_breakdown = Ai::UsageStatisticsService.model_breakdown(@start_date, @end_date)
  end

  # GET /admin/ai_usage/export
  def export
    start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : 30.days.ago.to_date
    end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : Date.current

    csv_data = Ai::UsageStatisticsService.export_data(start_date, end_date)

    send_data csv_data,
              filename: "ai_usage_#{start_date}_#{end_date}.csv",
              type: "text/csv; charset=utf-8",
              disposition: "attachment"
  rescue Date::Error => e
    redirect_to admin_ai_usage_index_path, alert: "日付の形式が不正です"
  rescue => e
    Rails.logger.error("AI usage export failed: #{e.message}")
    redirect_to admin_ai_usage_index_path, alert: "エクスポートに失敗しました"
  end
end
