# frozen_string_literal: true

require "rails_helper"

RSpec.describe Tag, type: :model do
  # S1-7 P1-3: タグ生成の唯一の入り口（旧: ArticleContentManager#find_or_create_tags）
  describe ".find_or_create_by_name" do
    it "新しいタグを入力の表記のまま作成する" do
      tag = described_class.find_or_create_by_name("Rails")

      expect(tag).to be_persisted
      expect(tag.name).to eq("Rails")
    end

    it "大文字小文字を無視して既存タグを再利用する" do
      existing = create(:tag, name: "Ruby")

      expect(described_class.find_or_create_by_name("RUBY")).to eq(existing)
      expect(described_class.count).to eq(1)
    end

    it "前後の空白を除去する" do
      tag = described_class.find_or_create_by_name("  Docker  ")

      expect(tag.name).to eq("Docker")
    end

    it "空文字・nilはnilを返し作成しない（境界値）" do
      expect(described_class.find_or_create_by_name("")).to be_nil
      expect(described_class.find_or_create_by_name(nil)).to be_nil
      expect(described_class.count).to eq(0)
    end

    it "バリデーションエラー時はログを残してnilを返す" do
      expect(Rails.logger).to receive(:warn).with(/Tag creation failed/)

      expect(described_class.find_or_create_by_name("a" * 51)).to be_nil
    end
  end
end
