require 'rails_helper'

RSpec.describe MyStorySectionJsonManager do
  before do
    MyStorySection.delete_all
  end

  describe 'timeline and chapter data helpers' do
    it 'normalizes arrays and persists updates for persisted sections' do
      section = create(:my_story_section, section_type: 'timeline', additional_data: {})
      manager = described_class.new(section)

      expect(manager.timeline_years).to eq([])

      manager.timeline_years = [ { 'year' => '2020' } ]
      section.reload

      expect(section.additional_data['years']).to eq([ { 'year' => '2020' } ])
    end

    it 'updates nested CTA and skills structures' do
      section = create(:my_story_section, section_type: 'cta', additional_data: {})
      manager = described_class.new(section)

      manager.cta_buttons = [ { 'label' => 'Go' } ]
      manager.skills_list = [ 'Ruby' ]
      section.reload

      expect(manager.cta_buttons).to eq([ { 'label' => 'Go' } ])
      expect(manager.skills_list).to eq([ 'Ruby' ])
    end
  end

  describe '#update_data and helpers' do
    it 'updates full data and supports key lookups' do
      section = create(:my_story_section, section_type: 'projects', additional_data: {})
      manager = described_class.new(section)

      manager.update_data('projects' => { 'items' => [ { 'name' => 'App' } ] })

      expect(manager.has_data?('projects')).to eq(true)
      expect(manager.project_items).to eq([ { 'name' => 'App' } ])

      manager.remove_data('projects')
      expect(manager.has_data?('projects')).to eq(false)
    end
  end
end
