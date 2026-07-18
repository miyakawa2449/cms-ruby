require 'rails_helper'

RSpec.describe SectionContentActivationService do
  before do
    SectionContent.delete_all
    ActiveRecord::Base.connection.reset_pk_sequence!('section_contents')
  end

  describe '#activate!' do
    it 'activates the content and returns a success message' do
      section = Section.find_by(name: 'hero') || create(:section, name: 'hero', display_name: 'Hero')
      content = create(:section_content, section: section, is_active: false)
      service = described_class.new(content)

      result = service.activate!

      expect(result[:success]).to eq(true)
      expect(content.reload.is_active).to eq(true)
    end

    it 'returns errors when activation fails' do
      section = Section.find_by(name: 'hero') || create(:section, name: 'hero', display_name: 'Hero')
      content = create(:section_content, section: section, is_active: false)
      service = described_class.new(content)

      allow(content).to receive(:activate!).and_raise(StandardError, 'boom')

      result = service.activate!

      expect(result[:success]).to eq(false)
      expect(result[:errors].first).to include('boom')
    end
  end

  describe '#deactivate!' do
    it 'deactivates content successfully' do
      section = Section.find_by(name: 'hero') || create(:section, name: 'hero', display_name: 'Hero')
      content = create(:section_content, section: section, is_active: true)
      service = described_class.new(content)

      result = service.deactivate!

      expect(result[:success]).to eq(true)
      expect(content.reload.is_active).to eq(false)
    end
  end

  describe '#toggle_active' do
    it 'toggles active state' do
      section = Section.find_by(name: 'hero') || create(:section, name: 'hero', display_name: 'Hero')
      content = create(:section_content, section: section, is_active: false)
      service = described_class.new(content)

      result = service.toggle_active

      expect(result[:success]).to eq(true)
      expect(content.reload.is_active).to eq(true)
    end

    it 'collects validation errors on failure' do
      section = Section.find_by(name: 'hero') || create(:section, name: 'hero', display_name: 'Hero')
      content = create(:section_content, section: section, is_active: true)
      service = described_class.new(content)

      allow(content).to receive(:update).and_return(false)
      allow(content).to receive(:errors)
        .and_return(instance_double(ActiveModel::Errors, full_messages: ['invalid']))

      result = service.toggle_active

      expect(result[:success]).to eq(false)
      expect(result[:errors]).to include('invalid')
    end
  end
end
