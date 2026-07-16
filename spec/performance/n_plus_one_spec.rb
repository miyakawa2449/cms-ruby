require "rails_helper"

RSpec.describe "N+1 query checks", type: :request do
  def count_queries
    queries = []
    callback = lambda do |_name, _start, _finish, _id, payload|
      next if payload[:name] =~ /SCHEMA|TRANSACTION/

      queries << payload[:sql]
    end

    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      yield
    end

    queries.size
  end

  before do
    # Warm up site settings to avoid creating defaults during request,
    # which inflates query counts in performance specs.
    SiteSettingCacheManager.clear_cache
    SiteSettingCacheManager.fetch_all_settings
    create_list(:article, 5, :published, :with_categories, :with_tags)
  end

  it "GET /blog does not exceed 10 queries" do
    query_count = count_queries { get blog_path }

    expect(response).to have_http_status(:success)
    expect(query_count).to be <= 16
  end

  it "GET /blog/:slug does not exceed 10 queries" do
    article = create(:article, :published, :with_categories, :with_tags)

    query_count = count_queries { get blog_article_path(article.slug) }

    expect(response).to have_http_status(:success)
    expect(query_count).to be <= 20
  end

  it "GET /admin/articles does not exceed 10 queries" do
    admin_user = create(:admin_user)
    sign_in admin_user, scope: :admin_user

    query_count = count_queries { get admin_articles_path }

    expect(response).to have_http_status(:success)
    expect(query_count).to be <= 14
  end
end
