# frozen_string_literal: true

# My Storyセクションの位置変更を管理するサービス
class MyStorySectionOrderingService
  attr_reader :section, :errors

  def initialize(section)
    @section = section
    @errors = []
  end

  def move_up
    previous_section = find_previous_section
    
    if previous_section
      swap_positions(previous_section, @section.position)
    else
      @errors << "これより上に移動できません。"
      false
    end
  end

  def move_down
    next_section = find_next_section
    
    if next_section
      swap_positions(next_section, @section.position)
    else
      @errors << "これより下に移動できません。"
      false
    end
  end

  def error_messages
    @errors.join(", ")
  end

  private

  def find_previous_section
    MyStorySection.where('position < ?', @section.position)
                  .order(position: :desc)
                  .first
  end

  def find_next_section
    MyStorySection.where('position > ?', @section.position)
                  .order(position: :asc)
                  .first
  end

  def swap_positions(other_section, current_position)
    MyStorySection.transaction do
      @section.update!(position: other_section.position)
      other_section.update!(position: current_position)
    end
    true
  rescue ActiveRecord::RecordInvalid => e
    @errors << "移動に失敗しました: #{e.message}"
    false
  end
end