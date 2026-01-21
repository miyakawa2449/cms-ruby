require 'rails_helper'

RSpec.describe Media::GenerateVariantsJob, type: :job do
  it 'generates variants when metadata exists' do
    metadata = double('MediaMetadata', generate_variants: true)
    allow(MediaMetadata).to receive(:find_by).and_return(metadata)

    described_class.new.perform(1)

    expect(metadata).to have_received(:generate_variants)
  end

  it 'returns when metadata is missing' do
    allow(MediaMetadata).to receive(:find_by).and_return(nil)

    expect { described_class.new.perform(999) }.not_to raise_error
  end

  it 're-raises errors from generate_variants' do
    metadata = double('MediaMetadata')
    allow(metadata).to receive(:generate_variants).and_raise(StandardError, 'boom')
    allow(MediaMetadata).to receive(:find_by).and_return(metadata)

    expect { described_class.new.perform(1) }.to raise_error(StandardError, 'boom')
  end
end
