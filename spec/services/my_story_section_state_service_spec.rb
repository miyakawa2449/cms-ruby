require 'rails_helper'

RSpec.describe MyStorySectionStateService do
  before do
    MyStorySection.delete_all
  end

  describe '#toggle_active' do
    it 'toggles state and returns success message' do
      section = create(:my_story_section, section_type: 'hero', is_active: true)
      service = described_class.new(section)

      result = service.toggle_active

      expect(result[:success]).to eq(true)
      expect(result[:is_active]).to eq(false)
      expect(section.reload.is_active).to eq(false)
    end

    it 'handles update failures' do
      section = create(:my_story_section, section_type: 'hero', is_active: true)
      service = described_class.new(section)

      allow(section).to receive(:update).and_return(false)
      allow(section).to receive_message_chain(:errors, :full_messages).and_return(["Update failed"])

      result = service.toggle_active

      expect(result[:success]).to eq(false)
      expect(result[:errors]).to include("Update failed")
    end
  end

  describe '#section_details' do
    it 'returns image flags and additional data keys' do
      section = create(:my_story_section, section_type: 'hero', additional_data: { 'skills' => [] })
      service = described_class.new(section)

      details = service.section_details

      expect(details[:has_background_image]).to eq(false)
      expect(details[:additional_data_keys]).to include('skills')
    end
  end
end
