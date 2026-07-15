require "rails_helper"
require Rails.root.join("db/migrate/20260715120000_fix_duplicate_service_sections.rb")

# 2026-07-15本番障害（service/servicesセクション並存によるトップページ500）の
# 再現と、修正マイグレーションの動作検証
RSpec.describe FixDuplicateServiceSections do
  subject(:migration) { described_class.new }

  def run_up
    ActiveRecord::Migration.suppress_messages { migration.up }
  end

  it "空の'service'と実コンテンツ入り'services'が並存する場合、統合される（本番障害の再現ケース）" do
    empty_service = create(:section, name: "service", display_name: "Service")
    services = create(:section, name: "services", display_name: "Services", position: 3)
    create(:section_content, section: services, is_active: true)

    run_up

    expect(Section.exists?(empty_service.id)).to be false
    expect(services.reload.name).to eq("service")
    expect(services.section_contents.count).to eq(1)
  end

  it "'services'のみ存在する場合はリネームされる" do
    services = create(:section, name: "services", display_name: "Services")

    run_up

    expect(services.reload.name).to eq("service")
  end

  it "'service'のみ存在する場合は何もしない" do
    service = create(:section, name: "service", display_name: "Service")

    run_up

    expect(service.reload.name).to eq("service")
  end

  it "両方にコンテンツがある場合は自動統合せず明示的に失敗する" do
    service = create(:section, name: "service", display_name: "Service")
    services = create(:section, name: "services", display_name: "Services", position: 3)
    create(:section_content, section: service, is_active: true)
    create(:section_content, section: services, is_active: true)

    expect { run_up }.to raise_error(/手動で整理/)
  end
end
