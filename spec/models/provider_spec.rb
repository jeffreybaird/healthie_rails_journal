# frozen_string_literal: true

require "rails_helper"
require_relative "../support/person_record_examples"

RSpec.describe Provider, type: :model do
  it_behaves_like "a person record"

  describe "#clients" do
    let(:provider) { described_class.create!(name: "Alex Morgan", email: "alex@example.test") }

    context "with shared, exclusive and unrelated clients" do
      let(:clients) do
        {
          shared: Client.create!(name: "Sam Rivera", email: "sam@example.test"),
          exclusive: Client.create!(name: "Alex Example", email: "exclusive@example.test"),
          additional: Client.create!(name: "Taylor Reed", email: "taylor@example.test"),
          unrelated: Client.create!(name: "Sam Rivera", email: "unrelated@example.test")
        }
      end

      before do
        other_provider = described_class.create!(name: "Jordan Lee", email: "jordan@example.test")
        %i[shared exclusive additional].each do |key|
          provider.provider_client_relationships.create!(client: clients.fetch(key), plan: "basic")
        end
        other_provider.provider_client_relationships.create!(client: clients.fetch(:shared), plan: "premium")
        other_provider.provider_client_relationships.create!(client: clients.fetch(:unrelated), plan: "basic")
      end

      it "returns a composable Active Record relation" do
        expect(provider.clients).to be_a(ActiveRecord::Relation)
      end

      it "returns every associated client, including a shared client, and excludes unrelated clients" do
        expect(provider.clients).to contain_exactly(
          clients.fetch(:shared), clients.fetch(:exclusive), clients.fetch(:additional)
        )
      end

      it "composes filtering and ordering while preserving the provider boundary" do
        relation = provider.clients.where(name: ["Taylor Reed", "Sam Rivera"]).order(name: :desc)

        expect(relation).to eq([clients.fetch(:additional), clients.fetch(:shared)])
      end
    end

    context "without relationships" do
      it "returns an empty relation that can still be filtered and ordered", :aggregate_failures do
        Client.create!(name: "Sam Rivera", email: "sam@example.test")
        relation = provider.clients.where(name: "Sam Rivera").order(:name)

        expect(relation).to be_a(ActiveRecord::Relation)
        expect(relation).to be_empty
      end
    end
  end
end
