require 'rails_helper'

RSpec.describe SectionContentParamsService do
  describe '.process' do
    it 'parses JSON content string' do
      params = ActionController::Parameters.new(
        section_content: {
          main_message: 'Hello',
          content: '{"title":"Hi"}'
        }
      )

      result = described_class.process(params)

      expect(result[:main_message]).to eq('Hello')
      expect(result[:content].to_unsafe_h).to eq({ 'title' => 'Hi' })
    end

    it 'returns empty content when JSON is invalid' do
      params = ActionController::Parameters.new(
        section_content: {
          content: '{invalid json}'
        }
      )

      result = described_class.process(params)

      expect(result[:content].to_unsafe_h).to eq({})
    end

    it 'handles structured content params' do
      params = ActionController::Parameters.new(
        section_content: {
          content: ActionController::Parameters.new(
            title: 'Title',
            skills: '["Ruby"]',
            services: 'invalid'
          )
        }
      )

      result = described_class.process(params)

      content = result[:content].to_unsafe_h
      expect(content[:title]).to eq('Title')
      expect(content[:skills]).to eq(['Ruby'])
      expect(content[:services]).to eq([])
    end
  end
end
