require "rails_helper"

# My Story独立ページは廃止済み（S1-1）。
# 検索エンジン等に残った旧URLはトップページの同名セクションへ301リダイレクトする。
RSpec.describe "旧My StoryページのURL", type: :request do
  it "トップページのMy Storyセクションへ301リダイレクトする" do
    get "/my-story"

    expect(response).to have_http_status(:moved_permanently)
    expect(response).to redirect_to("/#my-story")
  end
end
