require "rails_helper"

RSpec.describe AdminPathHistory, type: :model do
  describe "associations" do
    it { should belong_to(:admin_user) }
  end

  describe "validations" do
    it { should validate_presence_of(:old_path) }
    it { should validate_presence_of(:new_path) }
    it { should validate_presence_of(:change_type) }
  end

  describe "enums" do
    it {
      should define_enum_for(:change_type)
        .with_values(manual: "manual", auto_rotation: "auto_rotation", emergency: "emergency")
        .backed_by_column_of_type(:string)
    }
  end

  describe "scopes" do
    let!(:history1) { create(:admin_path_history, created_at: 1.day.ago) }
    let!(:history2) { create(:admin_path_history, created_at: 2.days.ago) }

    it "returns recent histories in descending order" do
      expect(AdminPathHistory.recent).to eq([ history1, history2 ])
    end

    it "filters by type" do
      emergency = create(:admin_path_history, change_type: "emergency")
      expect(AdminPathHistory.by_type("emergency")).to eq([ emergency ])
    end
  end
end
