require 'rails_helper'

RSpec.describe Positionable do
  before do
    SectionContent.delete_all
    Section.delete_all
    ActiveRecord::Base.connection.reset_pk_sequence!('section_contents')
    ActiveRecord::Base.connection.reset_pk_sequence!('sections')
  end

  it 'moves records up and down' do
    section_a = create(:section, name: 'a', display_name: 'A', position: 0)
    section_b = create(:section, name: 'b', display_name: 'B', position: 1)

    expect(section_b.move_up).to eq(true)
    expect(section_b.reload.position).to eq(0)

    expect(section_b.move_down).to eq(true)
    expect(section_b.reload.position).to eq(1)

    expect(section_b.move_to_first).to eq(true)
    expect(section_b.reload.position).to eq(0)

    expect(section_b.move_to_last).to eq(true)
    expect(section_b.reload.position).to eq(1)
  end

  it 'returns false for invalid move' do
    section = create(:section, name: 'only', display_name: 'Only', position: 0)

    expect(section.move_up).to eq(false)
    expect(section.move_to_position(-1)).to eq(false)
  end

  it 'calculates next position' do
    create(:section, name: 'a', display_name: 'A', position: 0)

    expect(Section.next_position).to eq(1)
  end
end
