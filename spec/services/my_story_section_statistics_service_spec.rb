require 'rails_helper'

RSpec.describe MyStorySectionStatisticsService do
  it 'computes section statistics and image usage' do
    section_a = build_stubbed(:my_story_section, section_type: 'hero', is_active: true)
    section_b = build_stubbed(:my_story_section, section_type: 'timeline', is_active: false)

    allow(section_a).to receive(:has_background_image?).and_return(true)
    allow(section_b).to receive(:has_background_image?).and_return(false)
    allow(section_a).to receive(:has_chapter_image?).and_return(false)
    allow(section_b).to receive(:has_chapter_image?).and_return(true)
    allow(section_a).to receive(:has_gallery_images?).and_return(false)
    allow(section_b).to receive(:has_gallery_images?).and_return(true)

    service = described_class.new([section_a, section_b])

    stats = service.calculate_stats

    expect(stats[:total_sections]).to eq(2)
    expect(stats[:active_sections]).to eq(1)
    expect(stats[:inactive_sections]).to eq(1)
    expect(stats[:section_type_distribution]).to eq({ 'hero' => 1, 'timeline' => 1 })
    expect(stats[:image_usage_stats][:with_background_image]).to eq(1)
    expect(stats[:image_usage_stats][:with_gallery_images]).to eq(1)
  end
end
