# frozen_string_literal: true

require "rails_helper"

RSpec.describe SecurityEvent, type: :model do
  describe "バリデーション" do
    it "有効なファクトリを持つ" do
      expect(build(:security_event)).to be_valid
    end

    it "event_typeが必須" do
      event = build(:security_event, event_type: nil)
      expect(event).not_to be_valid
    end

    it "定義外のevent_typeを拒否する" do
      event = build(:security_event, event_type: "unknown_event")
      expect(event).not_to be_valid
    end

    it "occurred_atが未設定なら現在時刻を補完する" do
      event = build(:security_event, occurred_at: nil)
      expect(event).to be_valid
      expect(event.occurred_at).to be_present
    end
  end

  describe "スコープ" do
    it "of_typeで種別を絞り込める（複数指定可）" do
      failure = create(:security_event, event_type: "login_failure")
      blocked = create(:security_event, event_type: "request_blocked")
      create(:security_event, event_type: "logout")

      expect(described_class.of_type("login_failure")).to contain_exactly(failure)
      expect(described_class.of_type(%w[login_failure request_blocked]))
        .to contain_exactly(failure, blocked)
    end

    it "occurred_betweenで期間を絞り込める" do
      within = create(:security_event, occurred_at: 2.days.ago)
      create(:security_event, occurred_at: 2.weeks.ago)

      expect(described_class.occurred_between(1.week.ago, Time.current))
        .to contain_exactly(within)
    end
  end

  describe ".purge_old!" do
    it "保持期間より古いイベントのみ削除する" do
      old_event = create(:security_event, occurred_at: 91.days.ago)
      recent_event = create(:security_event, occurred_at: 89.days.ago)

      expect { described_class.purge_old! }.to change(described_class, :count).by(-1)
      expect(described_class.exists?(old_event.id)).to be false
      expect(described_class.exists?(recent_event.id)).to be true
    end
  end
end
