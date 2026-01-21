require 'rails_helper'

RSpec.describe JsonStorable do
  before do
    MyStorySection.delete_all
  end

  let(:section) { create(:my_story_section, section_type: 'hero', additional_data: { 'foo' => 'bar' }) }

  it 'reads and writes json fields' do
    expect(section.read_json_field(:additional_data, 'foo')).to eq('bar')

    section.write_json_field(:additional_data, 'baz', 'qux')
    expect(section.additional_data['baz']).to eq('qux')

    section.write_json_field(:additional_data, 'baz', nil)
    expect(section.additional_data).not_to have_key('baz')
  end

  it 'updates and merges json fields' do
    expect(section.update_json_field(:additional_data, { 'a' => 1 })).to eq(true)
    expect(section.additional_data['a']).to eq(1)

    expect(section.merge_json_field(:additional_data, { 'b' => 2 })).to eq(true)
    expect(section.additional_data['b']).to eq(2)
  end

  it 'handles invalid updates gracefully' do
    expect(section.update_json_field(:additional_data, 'bad')).to eq(false)
    expect(section.merge_json_field(:additional_data, 'bad')).to eq(false)
  end

  it 'checks presence and keys' do
    expect(section.json_field_present?(:additional_data, 'foo')).to eq(true)
    expect(section.json_field_keys(:additional_data)).to include('foo')
  end

  it 'returns nil on parse errors' do
    allow(JSON).to receive(:parse).and_call_original
    allow(JSON).to receive(:parse).with('{bad').and_raise(JSON::ParserError)
    allow(section).to receive(:additional_data).and_return('{bad')

    expect(section.read_json_field(:additional_data, 'foo')).to eq(nil)
  end
end
