# frozen_string_literal: true

require "rails_helper"
require_relative "../support/sample_seed_contract"

RSpec.describe "SampleData" do
  include SampleSeedContract

  describe "the initial dataset" do
    let(:provider_rows) { SampleSeedContract::PROVIDERS.map { |key, name| ["seed-#{key}@example.test", name] } }
    let(:client_rows) { SampleSeedContract::CLIENTS.sort.map { |key, name| ["seed-#{key}@example.test", name] } }
    let(:relationship_rows) do
      [
        ["seed-alex@example.test", "seed-sam@example.test", "basic"],
        ["seed-alex@example.test", "seed-taylor@example.test", "premium"],
        ["seed-jordan@example.test", "seed-sam@example.test", "premium"],
        ["seed-jordan@example.test", "seed-riley@example.test", "basic"]
      ]
    end
    let(:journal_rows) do
      SampleSeedContract::ENTRIES.map do |label, client, day|
        ["seed-#{client}@example.test", seed_content(label), Time.utc(2026, 1, day)]
      end
    end

    before { load_sample_seeds }

    it "creates two named providers and four named clients at reserved synthetic addresses", :aggregate_failures do
      expect(Provider.order(:email).pluck(:email, :name)).to eq(provider_rows)
      expect(Client.order(:email).pluck(:email, :name)).to eq(client_rows)
    end

    it "gives the shared client different plans with each provider" do
      expect(seed_relationship_rows).to match_array(relationship_rows)
    end

    it "persists eight fictional entries with explicit dates and stable insertion order for ties" do
      expect(seed_journal_rows).to eq(journal_rows)
    end
  end

  describe "provider and client membership queries" do
    before { load_sample_seeds }

    it "returns exactly Alex's clients as a composable relation", :aggregate_failures do
      clients = seed_provider(:alex).clients.order(:email)
      expect(clients).to be_a(ActiveRecord::Relation)
      expect(clients).to eq([seed_client(:sam), seed_client(:taylor)])
    end

    it "returns exactly Jordan's clients" do
      expect(seed_provider(:jordan).clients.order(:email)).to eq([seed_client(:riley), seed_client(:sam)])
    end

    it "returns both of the shared client's providers as a composable relation", :aggregate_failures do
      providers = seed_client(:sam).providers.order(:email)
      expect(providers).to be_a(ActiveRecord::Relation)
      expect(providers).to eq([seed_provider(:alex), seed_provider(:jordan)])
    end

    it "returns exactly the exclusive clients' providers and leaves the unrelated client unassigned",
       :aggregate_failures do
      expect(seed_client(:taylor).providers).to eq([seed_provider(:alex)])
      expect(seed_client(:riley).providers).to eq([seed_provider(:jordan)])
      expect(seed_client(:unrelated).providers).to be_empty
    end
  end

  describe "client and provider history queries" do
    before { load_sample_seeds }

    it "returns all shared client entries newest first with later IDs first on equal dates", :aggregate_failures do
      history = seed_client(:sam).journal_entries.recent_first
      expect(history).to be_a(ActiveRecord::Relation)
      expect(history).to eq(seed_entries(%w[sam-tie-second sam-tie-first sam-middle sam-oldest]))
    end

    it "returns exactly Taylor's newest-first history" do
      expect(seed_client(:taylor).journal_entries.recent_first).to eq(seed_entries(%w[taylor-newest taylor-tie]))
    end

    it "returns exactly Riley's history" do
      expect(seed_client(:riley).journal_entries.recent_first).to eq([seed_entry("riley-newest")])
    end

    it "keeps the unrelated client's history available through its own client query" do
      expect(seed_client(:unrelated).journal_entries.recent_first).to eq([seed_entry("unrelated-newest")])
    end

    it "returns Alex's globally ordered history once per entry and excludes other clients", :aggregate_failures do
      history = seed_provider(:alex).journal_entries.recent_first
      expect(history).to be_a(ActiveRecord::Relation)
      expect(history).to eq(
        seed_entries(%w[taylor-newest sam-tie-second sam-tie-first taylor-tie sam-middle sam-oldest])
      )
    end

    it "returns Jordan's globally ordered history and excludes other clients" do
      expect(seed_provider(:jordan).journal_entries.recent_first).to eq(
        seed_entries(%w[riley-newest sam-tie-second sam-tie-first sam-middle sam-oldest])
      )
    end
  end

  describe "safe repeated loads" do
    it "preserves every record, ID and timestamp when run twice" do
      load_sample_seeds
      original = seed_database_snapshot
      load_sample_seeds
      expect(seed_database_snapshot).to eq(original)
    end

    context "with existing records outside the sample dataset" do
      let(:provider) { Provider.create!(name: "Existing Synthetic Provider", email: "existing-provider@example.test") }
      let(:client) { Client.create!(name: "Existing Synthetic Client", email: "existing-client@example.test") }
      let(:relationship) { ProviderClientRelationship.create!(provider: provider, client: client, plan: "premium") }
      let(:entry) do
        JournalEntry.create!(client: client, content: "An existing fictional note that the seed loader must preserve.",
                             created_at: Time.utc(2020, 1, 1))
      end
      let(:records) { [provider, client, relationship, entry] }

      it "preserves existing people, relationships, journal text, IDs and timestamps" do
        original = records.map(&:attributes)
        load_sample_seeds
        load_sample_seeds
        expect(reloaded_seed_attributes(records)).to eq(original)
      end
    end

    context "with case variants of reserved addresses" do
      let(:provider) { Provider.create!(name: "Customized Provider", email: "SEED-ALEX@example.test") }
      let(:client) { Client.create!(name: "Customized Client", email: "SEED-SAM@example.test") }
      let(:relationship) { ProviderClientRelationship.create!(provider: provider, client: client, plan: "premium") }
      let(:records) { [provider, client, relationship] }
      let!(:original) { records.map(&:attributes) }

      before do
        load_sample_seeds
        load_sample_seeds
      end

      it "reuses existing records without changing their names, email spelling, plan or timestamps" do
        expect(reloaded_seed_attributes(records)).to eq(original)
      end

      it "creates the missing samples without duplicating case variants", :aggregate_failures do
        expect(Provider.count).to eq(2)
        expect(Client.count).to eq(4)
        expect(ProviderClientRelationship.count).to eq(4)
        expect(client.journal_entries.count).to eq(4)
      end
    end

    context "with customized sample values" do
      let(:records) { customize_seed_records }
      let(:original) { records.map(&:attributes) }

      before do
        load_sample_seeds
        original
      end

      it "retains every edited attribute when the seeds run again" do
        load_sample_seeds
        expect(reloaded_seed_attributes(records)).to eq(original)
      end

      it "restores the original sample as a separate record without rewriting the edited note", :aggregate_failures do
        load_sample_seeds
        expect(seed_entry("sam-oldest").id).not_to eq(records.last.id)
        expect(JournalEntry.count).to eq(9)
      end

      it "preserves the restored sample and edited note on later reruns" do
        load_sample_seeds
        after_first_reload = seed_database_snapshot
        load_sample_seeds
        expect(seed_database_snapshot).to eq(after_first_reload)
      end
    end
  end
end
