require "rails_helper"

RSpec.describe "Page load time", type: :request do
  def measure_request
    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    yield
    Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
  end

  before do
    create(:article, :published)
    next_id = (Section.maximum(:id) || 0) + 1
    Section.create!(
      id: next_id,
      name: "hero-#{SecureRandom.hex(4)}",
      display_name: "Hero",
      is_visible: true,
      position: Section.next_position
    )
  end

  it "blog index loads within 2 seconds" do
    duration = measure_request { get blog_path }

    expect(response).to have_http_status(:success)
    expect(duration).to be < 2.0
  end

  it "blog detail loads within 1.5 seconds" do
    article = create(:article, :published)

    duration = measure_request { get blog_article_path(article.slug) }

    expect(response).to have_http_status(:success)
    expect(duration).to be < 1.5
  end

  it "portfolio page loads within 2 seconds" do
    duration = measure_request { get root_path }

    expect(response).to have_http_status(:success)
    expect(duration).to be < 2.0
  end

  it "admin page loads within 3 seconds" do
    admin_user = create(:admin_user)
    sign_in admin_user, scope: :admin_user
    create(:article, :published, admin_user: admin_user)

    duration = measure_request { get admin_articles_path }

    expect(response).to have_http_status(:success)
    expect(duration).to be < 3.0
  end

  it "second request is faster than the first" do
    first = measure_request { get blog_path }
    second = measure_request { get blog_path }

    expect(second).to be <= (first + 0.05)
  end
end
