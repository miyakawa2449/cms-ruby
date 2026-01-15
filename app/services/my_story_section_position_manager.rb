class MyStorySectionPositionManager
  def initialize(section)
    @section = section
  end

  # 位置を上に移動
  def move_up
    return false if @section.position <= 0

    target_position = @section.position - 1
    swap_with_position(target_position)
  end

  # 位置を下に移動
  def move_down
    max_position = MyStorySection.maximum(:position) || 0
    return false if @section.position >= max_position

    target_position = @section.position + 1
    swap_with_position(target_position)
  end

  # 指定位置に移動
  def move_to_position(new_position)
    return false if new_position < 0

    max_position = MyStorySection.maximum(:position) || 0
    new_position = [ new_position, max_position ].min

    old_position = @section.position

    MyStorySection.transaction do
      if new_position > old_position
        # 下に移動：間のアイテムを上にシフト
        MyStorySection.where(
          "position > ? AND position <= ?",
          old_position,
          new_position
        ).update_all("position = position - 1")
      elsif new_position < old_position
        # 上に移動：間のアイテムを下にシフト
        MyStorySection.where(
          "position >= ? AND position < ?",
          new_position,
          old_position
        ).update_all("position = position + 1")
      end

      @section.update!(position: new_position)
    end

    true
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Position update failed: #{e.message}"
    false
  end

  # 最後の位置に移動
  def move_to_last
    max_position = MyStorySection.maximum(:position) || 0
    move_to_position(max_position)
  end

  # 最初の位置に移動
  def move_to_first
    move_to_position(0)
  end

  # 位置の正規化（重複・欠番の修正）
  def self.normalize_positions
    MyStorySection.transaction do
      sections = MyStorySection.order(:position, :created_at)
      sections.each_with_index do |section, index|
        section.update_column(:position, index) if section.position != index
      end
    end
  end

  # 次に挿入される位置を取得
  def self.next_position
    (MyStorySection.maximum(:position) || -1) + 1
  end

  # 位置の重複チェック
  def self.validate_positions
    positions = MyStorySection.pluck(:position)
    duplicates = positions.group_by(&:itself).select { |_, v| v.size > 1 }.keys

    if duplicates.any?
      Rails.logger.warn "Duplicate positions found: #{duplicates}"
      return false
    end

    true
  end

  private

  def swap_with_position(target_position)
    target_section = MyStorySection.find_by(position: target_position)
    return false unless target_section

    MyStorySection.transaction do
      current_position = @section.position

      # 一時的に-1に設定してユニーク制約を回避
      @section.update!(position: -1)
      target_section.update!(position: current_position)
      @section.update!(position: target_position)
    end

    true
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Position swap failed: #{e.message}"
    false
  end
end
