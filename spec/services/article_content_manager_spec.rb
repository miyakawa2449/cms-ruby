require 'rails_helper'

RSpec.describe ArticleContentManager do
  describe 'tech stack helpers' do
    it 'parses and updates tech stack list' do
      article = create(:article, tech_stack: 'Ruby, Rails')
      manager = described_class.new(article)

      expect(manager.tech_stack_list).to eq(['Ruby', 'Rails'])

      manager.add_tech_stack('PostgreSQL')
      expect(article.reload.tech_stack).to include('PostgreSQL')

      manager.remove_tech_stack('Ruby')
      expect(article.reload.tech_stack).not_to include('Ruby')
    end
  end

  describe 'content helpers' do
    it 'calculates word count and reading time' do
      article = build(:article, content: 'word ' * 400)
      manager = described_class.new(article)

      expect(manager.content_word_count).to eq(400)
      expect(manager.content_reading_time).to eq(2)
    end

    it 'generates and updates excerpts' do
      article = create(:article, excerpt: nil, content: '# Title\n**Bold** content')
      manager = described_class.new(article)

      excerpt = manager.generate_excerpt(length: 10)
      expect(excerpt).to include('Title')

      manager.update_excerpt(force: true)
      expect(article.reload.excerpt).to be_present
    end
  end

  describe 'tags and categories' do
    it 'assigns tags from comma separated list' do
      article = create(:article)
      manager = described_class.new(article)

      manager.assign_tag_names('Ruby, Rails')

      expect(article.tags.pluck(:name)).to include('Ruby', 'Rails')
    end

    it 'detects work category' do
      works = Category.find_by(slug: 'works') || create(:category, slug: 'works')
      article = create(:article)
      article.categories << works

      manager = described_class.new(article)

      expect(manager.is_work?).to eq(true)
    end
  end

  describe '#work_type_display' do
    it 'maps work types to labels' do
      article = create(:article, work_type: 'github')
      manager = described_class.new(article)

      expect(manager.work_type_display).to eq('GitHub プロジェクト')
    end
  end
end
