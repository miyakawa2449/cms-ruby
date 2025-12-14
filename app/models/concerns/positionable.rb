# frozen_string_literal: true

module Positionable
  extend ActiveSupport::Concern

  included do
    validates :position, presence: true, numericality: { greater_than_or_equal_to: 0 }
    scope :ordered, -> { order(:position) }
  end

  class_methods do
    def next_position
      (maximum(:position) || -1) + 1
    end
  end

  def move_up
    return false if position <= 0
    
    swap_positions(position, position - 1)
  end

  def move_down
    max_position = self.class.maximum(:position) || 0
    return false if position >= max_position
    
    swap_positions(position, position + 1)
  end

  def move_to_position(new_position)
    return true if position == new_position
    return false if new_position < 0
    
    max_position = self.class.maximum(:position) || 0
    target_position = [new_position, max_position].min
    
    self.class.transaction do
      if position < target_position
        # 下に移動: 間の要素を上にシフト
        self.class.where(position: (position + 1)..target_position)
                  .update_all('position = position - 1')
      else
        # 上に移動: 間の要素を下にシフト  
        self.class.where(position: target_position..(position - 1))
                  .update_all('position = position + 1')
      end
      
      update_column(:position, target_position)
    end
    
    true
  end

  def move_to_first
    move_to_position(0)
  end

  def move_to_last
    move_to_position(self.class.maximum(:position) || 0)
  end

  private

  def swap_positions(pos1, pos2)
    other = self.class.find_by(position: pos2)
    return false unless other
    
    self.class.transaction do
      # 一時的に負の値を使用して重複を避ける
      temp_position = -1
      update_column(:position, temp_position)
      other.update_column(:position, pos1)
      update_column(:position, pos2)
    end
    
    reload
    true
  rescue ActiveRecord::RecordNotFound, ActiveRecord::StatementInvalid
    false
  end
end