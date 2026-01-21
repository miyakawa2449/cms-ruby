# frozen_string_literal: true

require "rails_helper"

RSpec.describe PortfolioController, type: :controller do
  describe "#index" do
    before do
      allow(Article).to receive_message_chain(:joins, :where, :pluck).and_return([])
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

    it "handles standard errors and clears assigns" do
      allow(Section).to receive_message_chain(:visible, :ordered, :preload).and_raise(StandardError, "boom")
      allow(Rails.logger).to receive(:error)

      get :index

      expect(assigns(:sections)).to eq([])
      expect(assigns(:section_data)).to eq({})
      expect(assigns(:recent_articles)).to eq([])
    end

    it "retries once when DB connection is lost" do
      visible_relation = double("VisibleRelation")
      ordered_relation = double("OrderedRelation")
      allow(visible_relation).to receive(:ordered).and_return(ordered_relation)
      allow(ordered_relation).to receive(:preload).and_return([])

      attempts = 0
      allow(Section).to receive(:visible) do
        attempts += 1
        attempts == 1 ? raise(ActiveRecord::ConnectionNotEstablished) : visible_relation
      end
      allow(ActiveRecord::Base).to receive(:establish_connection)
      allow(Article).to receive_message_chain(:published, :includes, :where, :not, :recent, :limit).and_return([])
      allow(Rails.logger).to receive(:error)

      get :index

      expect(ActiveRecord::Base).to have_received(:establish_connection)
      expect(assigns(:sections)).to eq([])
      expect(assigns(:section_data)).to eq({})
    end
  end
end
