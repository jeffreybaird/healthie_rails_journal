# frozen_string_literal: true

require "rails_helper"
require_relative "../support/person_record_examples"

RSpec.describe Client, type: :model do
  it_behaves_like "a person record"

  describe "#providers" do
    let(:client) { described_class.create!(name: "Sam Rivera", email: "sam@example.test") }

    context "with shared, exclusive and unrelated providers" do
      let(:providers) do
        {
          shared: Provider.create!(name: "Alex Morgan", email: "alex@example.test"),
          exclusive: Provider.create!(name: "Jordan Lee", email: "jordan@example.test"),
          additional: Provider.create!(name: "Taylor Reed", email: "taylor@example.test"),
          unrelated: Provider.create!(name: "Alex Morgan", email: "unrelated@example.test")
        }
      end

      before do
        other_client = described_class.create!(name: "Avery Example", email: "avery@example.test")
        client.provider_client_relationships.create!(provider: providers.fetch(:shared), plan: "basic")
        client.provider_client_relationships.create!(provider: providers.fetch(:exclusive), plan: "premium")
        client.provider_client_relationships.create!(provider: providers.fetch(:additional), plan: "basic")
        other_client.provider_client_relationships.create!(provider: providers.fetch(:shared), plan: "premium")
        other_client.provider_client_relationships.create!(provider: providers.fetch(:unrelated), plan: "basic")
      end

      it "returns a composable Active Record relation" do
        expect(client.providers).to be_a(ActiveRecord::Relation)
      end

      it "returns every associated provider regardless of plan and excludes unrelated providers" do
        expect(client.providers).to contain_exactly(
          providers.fetch(:shared), providers.fetch(:exclusive), providers.fetch(:additional)
        )
      end

      it "composes filtering and ordering while preserving the client boundary" do
        relation = client.providers.where(name: ["Taylor Reed", "Alex Morgan"]).order(name: :desc)

        expect(relation).to eq([providers.fetch(:additional), providers.fetch(:shared)])
      end
    end

    context "without relationships" do
      before do
        other_client = described_class.create!(name: "Avery Example", email: "avery@example.test")
        provider = Provider.create!(name: "Alex Morgan", email: "alex@example.test")
        other_client.provider_client_relationships.create!(provider: provider, plan: "basic")
      end

      it "returns an empty relation that can still be filtered and ordered", :aggregate_failures do
        relation = client.providers.where(name: "Alex Morgan").order(:name)

        expect(relation).to be_a(ActiveRecord::Relation)
        expect(relation).to be_empty
      end
    end
  end
end
