require "rails_helper"

# 予約投稿の仕様（2026-07-15確定・回答1「完成させる」):
# - status=scheduled + published_at（予約時刻）で保存
# - 定期ジョブが予約時刻を過ぎた記事を published に昇格させる
# - published_at は予約時刻を維持する（ジョブ実行時刻で上書きしない）
RSpec.describe PublishScheduledArticlesJob, type: :job do
  let(:admin_user) { create(:admin_user) }

  def create_scheduled(published_at:)
    create(:article, admin_user: admin_user, status: "scheduled", published_at: published_at)
  end

  it "予約時刻を過ぎた記事を公開する" do
    article = create_scheduled(published_at: 10.minutes.ago)

    described_class.perform_now

    expect(article.reload.status).to eq("published")
  end

  it "published_atは予約時刻のまま維持される" do
    scheduled_time = 10.minutes.ago
    article = create_scheduled(published_at: scheduled_time)

    described_class.perform_now

    expect(article.reload.published_at).to be_within(1.second).of(scheduled_time)
  end

  it "公開された記事はpublishedスコープに含まれる" do
    article = create_scheduled(published_at: 10.minutes.ago)

    described_class.perform_now

    expect(Article.published).to include(article)
  end

  it "予約時刻が未来の記事は公開しない" do
    article = create_scheduled(published_at: 1.day.from_now)

    described_class.perform_now

    expect(article.reload.status).to eq("scheduled")
  end

  it "下書き・アーカイブ記事には影響しない" do
    draft = create(:article, admin_user: admin_user, status: "draft", published_at: nil)
    archived = create(:article, admin_user: admin_user, status: "archived", published_at: 1.day.ago)

    described_class.perform_now

    expect(draft.reload.status).to eq("draft")
    expect(archived.reload.status).to eq("archived")
  end

  it "recurring.ymlの本番スケジュールに登録されている" do
    recurring = YAML.load_file(Rails.root.join("config/recurring.yml"))
    job_entries = recurring["production"].values.map { |v| v["class"] }

    expect(job_entries).to include("PublishScheduledArticlesJob")
  end
end
