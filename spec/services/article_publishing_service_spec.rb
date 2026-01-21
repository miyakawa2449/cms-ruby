require "rails_helper"

RSpec.describe ArticlePublishingService do
  let(:article) { create(:article, status: "draft", published_at: nil) }
  let(:service) { described_class.new(article) }

  describe "#publish" do
    it "publishes the article" do
      result = service.publish

      expect(result[:success]).to eq(true)
      expect(article.reload.status).to eq("published")
      expect(article.published_at).to be_present
    end

    it "returns errors when update fails" do
      allow(article).to receive(:update).and_return(false)
      allow(article).to receive_message_chain(:errors, :full_messages).and_return(["bad"])

      result = service.publish

      expect(result[:success]).to eq(false)
      expect(result[:errors]).to include("bad")
    end
  end

  describe "#unpublish" do
    it "unpublishes the article" do
      article.update!(status: "published", published_at: Time.current)

      result = service.unpublish

      expect(result[:success]).to eq(true)
      expect(article.reload.status).to eq("draft")
      expect(article.published_at).to be_nil
    end
  end

  describe "#toggle_publish" do
    it "publishes when draft" do
      result = service.toggle_publish

      expect(result[:success]).to eq(true)
      expect(article.reload.status).to eq("published")
    end
  end

  describe "#schedule_publish" do
    it "sets scheduled status and time" do
      scheduled_at = 2.days.from_now

      result = service.schedule_publish(scheduled_at)

      expect(result[:success]).to eq(true)
      expect(article.reload.status).to eq("scheduled")
      expect(article.published_at.to_i).to eq(scheduled_at.to_i)
    end
  end
end
