# frozen_string_literal: true

module Admin
  module StatsHelper
    # 色付き統計タイル（admin/shared/_stat_tile）の配色。
    # Tailwindのクラス検出（purge）に載せるため、クラス名は文字列リテラルで列挙する
    # （"bg-#{color}-50" のような動的生成はビルド後のCSSから消えるので不可）
    STAT_TILE_COLORS = {
      red:    { bg: "bg-red-50",    value: "text-red-600",    label: "text-red-800" },
      orange: { bg: "bg-orange-50", value: "text-orange-600", label: "text-orange-800" },
      yellow: { bg: "bg-yellow-50", value: "text-yellow-600", label: "text-yellow-800" },
      blue:   { bg: "bg-blue-50",   value: "text-blue-600",   label: "text-blue-800" },
      green:  { bg: "bg-green-50",  value: "text-green-600",  label: "text-green-800" },
      purple: { bg: "bg-purple-50", value: "text-purple-600", label: "text-purple-800" },
      gray:   { bg: "bg-gray-50",   value: "text-gray-600",   label: "text-gray-800" },
      # 「総数」系タイル: 背景はグレーのまま値を濃色で強調する
      total:  { bg: "bg-gray-50",   value: "text-gray-900",   label: "text-gray-600" }
    }.freeze

    def stat_tile_colors(color)
      STAT_TILE_COLORS.fetch(color.to_sym)
    end
  end
end
