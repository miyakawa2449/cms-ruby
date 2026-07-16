# frozen_string_literal: true

require "rails_helper"

RSpec.describe PortfolioController, type: :controller do
  describe "#index" do
    before do
      allow(Article).to receive_message_chain(:joins, :where, :pluck).and_return([])
      # Worksセクション用クエリ（並び順バグ修正で追加）のスタブ
      # NOTE: このファイルのmessage_chainモック依存はS1-7(P5-6)で実レコードベースに書き換え予定
      allow(Article).to receive_message_chain(:published, :joins, :where, :order, :includes, :limit, :to_a).and_return([])
    end

    it "assigns sections and recent articles" do
      allow(Section).to receive_message_chain(:visible, :ordered, :preload).and_return([])
      allow(Article).to receive_message_chain(:published, :includes, :where, :not, :recent, :limit).and_return([])

      get :index

      expect(assigns(:sections)).to eq([])
      expect(assigns(:section_data)).to eq({})
      expect(assigns(:recent_articles)).to eq([])
    end

    it "applies search when query is present" do
      allow(Section).to receive_message_chain(:visible, :ordered, :preload).and_return([])
      recent_relation = double("RecentRelation")
      allow(recent_relation).to receive(:search_by_content).with("ruby").and_return([:hit])
      allow(Article).to receive_message_chain(:published, :includes, :where, :not, :recent, :limit).and_return(recent_relation)

      get :index, params: { search: "ruby" }

      expect(assigns(:search_query)).to eq("ruby")
      expect(assigns(:recent_articles)).to eq([:hit])
    end

    # S1-7 P0-1: 例外を握りつぶして空ページ200を返す設計と、
    # ConnectionNotEstablishedの無限retryを撤去したため、例外はそのまま伝播する
    # （回帰テストは spec/requests/audit_regression_spec.rb 参照）
    it "does not swallow errors from data loading" do
      allow(Section).to receive(:visible).and_raise(StandardError, "boom")

      expect { get :index }.to raise_error(StandardError, "boom")
    end
  end
end
