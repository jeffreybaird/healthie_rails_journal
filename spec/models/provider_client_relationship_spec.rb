# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProviderClientRelationship, type: :model do
  let(:provider) { Provider.create!(name: "Alex Morgan", email: "alex@example.test") }
  let(:client) { Client.create!(name: "Sam Rivera", email: "sam@example.test") }
  let(:attributes) { { provider: provider, client: client, plan: "basic" } }

  describe "persistence" do
    %w[basic premium].each do |plan|
      it "stores a #{plan} plan on the provider-client relationship" do
        relationship = described_class.create!(**attributes, plan: plan)

        expect(described_class.find(relationship.id)).to have_attributes(provider: provider, client: client, plan: plan)
      end
    end
  end

  describe "plan validation" do
    [nil, "", "enterprise", "BASIC", " basic "].each do |plan|
      it "rejects #{plan.inspect} as a plan without persisting", :aggregate_failures do
        relationship = described_class.new(**attributes, plan: plan)

        expect(relationship.save).to be(false)
        expect(relationship.errors[:plan]).not_to be_empty
        expect(described_class.count).to eq(0)
      end
    end

    it "rejects an omitted plan rather than selecting a default", :aggregate_failures do
      relationship = described_class.new(attributes.except(:plan))

      expect(relationship.save).to be(false)
      expect(relationship.errors[:plan]).not_to be_empty
      expect(described_class.count).to eq(0)
    end
  end

  describe "required associations" do
    %i[provider client].each do |association|
      it "belongs to a #{association}", :aggregate_failures do
        reflection = described_class.reflect_on_association(association)

        expect(reflection.macro).to eq(:belongs_to)
        expect(reflection.klass).to eq(association.to_s.classify.constantize)
      end

      it "rejects a missing #{association}", :aggregate_failures do
        relationship = described_class.new(**attributes, association => nil)

        expect(relationship.save).to be(false)
        expect(relationship.errors[association]).not_to be_empty
        expect(described_class.count).to eq(0)
      end

      it "rejects a #{association} ID that does not exist", :aggregate_failures do
        relationship = described_class.new(attributes.except(association))
        relationship.public_send("#{association}_id=", 999_999)

        expect(relationship.save).to be(false)
        expect(relationship.errors[association]).not_to be_empty
        expect(described_class.count).to eq(0)
      end
    end
  end

  describe "one relationship per provider-client pair" do
    let!(:relationship) { described_class.create!(attributes) }

    it "rejects a duplicate pair even when the attempted plan differs", :aggregate_failures do
      duplicate = described_class.new(**attributes, plan: "premium")

      expect(duplicate.save).to be(false)
      expect(duplicate.errors.details.values.flatten).to include(a_hash_including(error: :taken))
      expect(described_class.all).to eq([relationship])
      expect(relationship.reload.plan).to eq("basic")
    end

    it "allows another client to have a relationship with the same provider", :aggregate_failures do
      other_client = Client.create!(name: "Taylor Reed", email: "taylor@example.test")
      other_relationship = described_class.create!(provider: provider, client: other_client, plan: "premium")

      expect(provider.clients).to contain_exactly(client, other_client)
      expect(described_class.all).to contain_exactly(relationship, other_relationship)
    end

    it "enforces pair uniqueness when model validation is bypassed", :aggregate_failures do
      duplicate = described_class.new(**attributes, plan: "premium")

      expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
      expect(described_class.all).to eq([relationship])
      expect(relationship.reload.plan).to eq("basic")
    end

    it "has a unique composite index covering both relationship IDs" do
      indexes = described_class.connection.indexes(described_class.table_name)
      unique_columns = indexes.select(&:unique).map(&:columns)

      expect(unique_columns).to include(match_array(%w[provider_id client_id]))
    end
  end

  describe "database constraints" do
    %i[provider_id client_id plan].each do |column|
      it "rejects null #{column} when validation is bypassed", :aggregate_failures do
        relationship = described_class.new(attributes)
        relationship.public_send("#{column}=", nil)

        expect { relationship.save!(validate: false) }.to raise_error(ActiveRecord::NotNullViolation)
        expect(described_class.count).to eq(0)
      end
    end

    %i[provider client].each do |association|
      it "enforces the #{association} foreign key when validation is bypassed", :aggregate_failures do
        relationship = described_class.new(attributes.except(association))
        relationship.public_send("#{association}_id=", 999_999)

        expect { relationship.save!(validate: false) }.to raise_error(ActiveRecord::InvalidForeignKey)
        expect(described_class.count).to eq(0)
      end

      it "prevents deleting a #{association} referenced by a relationship", :aggregate_failures do
        relationship = described_class.create!(attributes)
        parent = relationship.public_send(association)

        expect { parent.delete }.to raise_error(ActiveRecord::InvalidForeignKey)
        expect(parent.class.find(parent.id)).to eq(parent)
        expect(relationship.reload).to be_persisted
      end
    end
  end

  describe "bidirectional collections" do
    { Provider => :clients, Client => :providers }.each do |model, collection|
      it "declares #{model}'s direct relationship collection", :aggregate_failures do
        direct = model.reflect_on_association(:provider_client_relationships)

        expect(direct.macro).to eq(:has_many)
        expect(direct.klass).to eq(described_class)
      end

      it "declares #{model}'s #{collection} as a has-many-through collection", :aggregate_failures do
        through = model.reflect_on_association(collection)

        expect(through.macro).to eq(:has_many)
        expect(through.through_reflection.name).to eq(:provider_client_relationships)
      end
    end

    context "with a shared client and an unrelated relationship" do
      let(:shared_relationships) do
        second_provider = Provider.create!(name: "Jordan Lee", email: "jordan@example.test")
        second_client = Client.create!(name: "Taylor Reed", email: "taylor@example.test")
        {
          provider: second_provider, client: second_client,
          basic: described_class.create!(attributes),
          premium: described_class.create!(provider: second_provider, client: client, plan: "premium"),
          unrelated: described_class.create!(provider: second_provider, client: second_client, plan: "basic")
        }
      end

      before { shared_relationships }

      def other_provider
        shared_relationships.fetch(:provider)
      end

      def other_client
        shared_relationships.fetch(:client)
      end

      it "scopes each provider's clients to that provider's relationships", :aggregate_failures do
        expect(provider.clients).to eq([client])
        expect(other_provider.clients).to contain_exactly(client, other_client)
      end

      it "scopes each client's providers to that client's relationships", :aggregate_failures do
        expect(client.providers).to contain_exactly(provider, other_provider)
        expect(other_client.providers).to eq([other_provider])
      end

      it "exposes each provider's own relationship records", :aggregate_failures do
        expect(provider.provider_client_relationships).to eq([shared_relationships.fetch(:basic)])
        expect(other_provider.provider_client_relationships).to contain_exactly(
          shared_relationships.fetch(:premium), shared_relationships.fetch(:unrelated)
        )
      end

      it "exposes each client's own relationship records", :aggregate_failures do
        expect(client.provider_client_relationships).to contain_exactly(
          shared_relationships.fetch(:basic), shared_relationships.fetch(:premium)
        )
        expect(other_client.provider_client_relationships).to eq([shared_relationships.fetch(:unrelated)])
      end

      it "stores a different plan for each provider of the same client", :aggregate_failures do
        expect(shared_relationships.fetch(:basic).reload.plan).to eq("basic")
        expect(shared_relationships.fetch(:premium).reload.plan).to eq("premium")
      end
    end

    it "returns empty collections for people without relationships", :aggregate_failures do
      expect(provider.clients).to be_empty
      expect(provider.provider_client_relationships).to be_empty
      expect(client.providers).to be_empty
      expect(client.provider_client_relationships).to be_empty
    end
  end
end
