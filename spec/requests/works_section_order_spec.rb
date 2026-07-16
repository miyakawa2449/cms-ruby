require "rails_helper"

# 剛さん報告のバグ（2026-07-16）の回帰テスト:
# トップページWorksセクションの実績がランダム順に見える
# → 原因はORDER BY句のないクエリ（並び順がDB任せで不定）。
# 仕様: 公開日時の新しい順（published_at DESC）で表示する。
RSpec.describe "トップページWorksセクションの表示順", type: :request do
  let(:admin_user) { create(:admin_user) }

  it "実績が公開日時の新しい順に表示される" do
    section = create(:section, name: "works", display_name: "Works", is_visible: true)
    create(:section_content, section: section, is_active: true)
    works_category = create(:category, name: "実績", slug: "works")

    # 登録順と公開日順をわざとずらす（ORDER BYが無いと登録順で返りがちなため）
    oldest = create(:article, admin_user: admin_user, title: "実績いちばん古い",
                    status: "published", published_at: 3.days.ago)
    newest = create(:article, admin_user: admin_user, title: "実績いちばん新しい",
                    status: "published", published_at: 1.day.ago)
    middle = create(:article, admin_user: admin_user, title: "実績まんなか",
                    status: "published", published_at: 2.days.ago)
    [ oldest, newest, middle ].each { |article| article.categories << works_category }

    get root_path

    body = response.body
    expect(body.index("実績いちばん新しい")).to be < body.index("実績まんなか")
    expect(body.index("実績まんなか")).to be < body.index("実績いちばん古い")
  end

  it "7件以上ある場合は新しい6件だけが表示される" do
    section = create(:section, name: "works", display_name: "Works", is_visible: true)
    create(:section_content, section: section, is_active: true)
    works_category = create(:category, name: "実績", slug: "works")

    articles = 7.times.map do |i|
      create(:article, admin_user: admin_user, title: "実績記事#{i}号",
             status: "published", published_at: (i + 1).days.ago)
    end
    articles.each { |article| article.categories << works_category }

    get root_path

    expect(response.body).to include("実績記事0号")   # 最新
    expect(response.body).not_to include("実績記事6号") # 最古（7件目）は非表示
  end
end
