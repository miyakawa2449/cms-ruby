require 'rails_helper'

RSpec.describe MyStorySectionTypeService do
  describe '.available_types_for' do
    it 'excludes existing types for new sections' do
      MyStorySection.delete_all
      create(:my_story_section, section_type: 'hero')

      options = described_class.available_types_for
      types = options.map(&:last)

      expect(types).not_to include('hero')
    end

    it 'includes current type for persisted section' do
      MyStorySection.delete_all
      section = create(:my_story_section, section_type: 'timeline')

      options = described_class.available_types_for(section)
      types = options.map(&:last)

      expect(types).to include('timeline')
    end
  end
end
