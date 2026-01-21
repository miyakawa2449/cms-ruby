require 'rails_helper'

RSpec.describe SectionContent, type: :model do
  let(:section) { Section.find_by(name: 'hero') || create(:section, name: 'hero', display_name: 'Hero') }

  before do
    SectionContent.delete_all
    ActiveRecord::Base.connection.reset_pk_sequence!('section_contents')
  end

  it 'auto-assigns version and sets empty content when using individual fields' do
    content = SectionContent.create!(section: section, main_message: 'Hello')

    expect(content.version).to eq(1)
    expect(content.content).to eq({})
  end

  it 'activates and deactivates versions' do
    first = create(:section_content, section: section, is_active: true)
    second = create(:section_content, section: section, is_active: false)

    second.activate!

    expect(second.reload.is_active).to eq(true)
    expect(first.reload.is_active).to eq(false)

    second.deactivate!
    expect(second.reload.is_active).to eq(false)
  end

  it 'detects individual fields' do
    content = build(:section_content, section: section, main_message: 'Hello')

    expect(content.has_individual_fields?).to eq(true)
  end
end
