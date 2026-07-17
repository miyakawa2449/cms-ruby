# frozen_string_literal: true

# is_visibleフラグを持つモデル（Section等）の表示/非表示スコープ。
# S1-7 P1-6で解体: 旧実装はstatus/is_active/is_visible/active_contentを
# respond_to?で分岐する万能concernだったが、記事系のロジックは
# ArticlePublishingManagerに統合し、ここはvisibleスコープのみに縮小した。
# （Sectionにstatusカラムは無いため、旧 `Section.published` はSQLエラーになる地雷だった）
module Publishable
  extend ActiveSupport::Concern

  included do
    scope :visible, -> { where(is_visible: true) }
  end
end
