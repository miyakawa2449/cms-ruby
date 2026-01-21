require 'rails_helper'

RSpec.describe MyStorySectionPositionManager do
  before do
    MyStorySection.delete_all
  end

  describe '#move_up and #move_down' do
    it 'swaps positions with neighboring sections' do
      section_a = create(:my_story_section, section_type: 'hero', position: 0)
      section_b = create(:my_story_section, section_type: 'timeline', position: 1)

      manager = described_class.new(section_b)

      expect(manager.move_up).to eq(false)
      expect(section_a.reload.position).to eq(0)
      expect(section_b.reload.position).to eq(1)

      expect(manager.move_down).to eq(false)
      expect(section_a.reload.position).to eq(0)
      expect(section_b.reload.position).to eq(1)
    end
  end

  describe '#move_to_position' do
    it 'shifts intermediate sections when moving down' do
      section_a = create(:my_story_section, section_type: 'hero', position: 0)
      section_b = create(:my_story_section, section_type: 'timeline', position: 1)
      section_c = create(:my_story_section, section_type: 'chapter_1', position: 2)

      manager = described_class.new(section_a)

      expect(manager.move_to_position(2)).to eq(true)
      expect(section_a.reload.position).to eq(2)
      expect(section_b.reload.position).to eq(0)
      expect(section_c.reload.position).to eq(1)
    end

    it 'returns false for invalid position' do
      section = create(:my_story_section, section_type: 'hero', position: 0)
      manager = described_class.new(section)

      expect(manager.move_to_position(-1)).to eq(false)
    end
  end

  describe '.normalize_positions and .validate_positions' do
    it 'normalizes gaps and detects duplicates' do
      create(:my_story_section, section_type: 'hero', position: 0)
      create(:my_story_section, section_type: 'timeline', position: 2)

      described_class.normalize_positions

      positions = MyStorySection.order(:position).pluck(:position)
      expect(positions).to eq([0, 1])
      expect(described_class.validate_positions).to eq(true)

      MyStorySection.update_all(position: 0)
      expect(described_class.validate_positions).to eq(false)
    end
  end

  describe '.next_position' do
    it 'returns next available position' do
      create(:my_story_section, section_type: 'hero', position: 0)

      expect(described_class.next_position).to eq(1)
    end
  end
end
