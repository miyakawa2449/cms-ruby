require 'rails_helper'

RSpec.describe MyStorySectionOrderingService do
  before do
    MyStorySection.delete_all
  end

  describe '#move_up and #move_down' do
    it 'moves sections when adjacent items exist' do
      section_a = create(:my_story_section, section_type: 'hero', position: 0)
      section_b = create(:my_story_section, section_type: 'timeline', position: 1)
      service = described_class.new(section_b)

      expect(service.move_up).to eq(true)
      expect(section_a.reload.position).to eq(1)
      expect(section_b.reload.position).to eq(0)

      expect(service.move_down).to eq(true)
      expect(section_a.reload.position).to eq(0)
      expect(section_b.reload.position).to eq(1)
    end

    it 'returns errors when no adjacent section exists' do
      section = create(:my_story_section, section_type: 'hero', position: 0)
      service = described_class.new(section)

      expect(service.move_up).to eq(false)
      expect(service.errors).not_to be_empty
    end
  end
end
