# frozen_string_literal: true

require "rails_helper"

RSpec.describe Provider, type: :model do
  describe "#journal_entries.recent_first" do
    let(:provider) { described_class.create!(name: "Alex Morgan", email: "alex@example.test") }
    let(:clients) do
      %i[shared exclusive without_entries unrelated unassigned].index_with do |label|
        Client.create!(name: "Synthetic #{label}", email: "#{label}@example.test")
      end
    end
    let(:entries) do
      [
        [:exclusive_newest, :exclusive, Time.utc(2026, 1, 20)],
        [:shared_oldest, :shared, Time.utc(2026, 1, 5)],
        [:exclusive_earlier_tie, :exclusive, Time.utc(2026, 1, 15)],
        [:shared_later_tie, :shared, Time.utc(2026, 1, 15)],
        [:shared_middle, :shared, Time.utc(2026, 1, 10)],
        [:unrelated_newest, :unrelated, Time.utc(2026, 1, 25)],
        [:unrelated_tie, :unrelated, Time.utc(2026, 1, 15)],
        [:unassigned_newest, :unassigned, Time.utc(2026, 1, 30)]
      ].to_h do |label, owner, timestamp|
        entry = JournalEntry.create!(
          client: clients.fetch(owner),
          content: "A synthetic journal reflection with sufficient detail for #{label}.",
          created_at: timestamp, updated_at: Time.utc(2026, 2, 1)
        )
        [label, entry]
      end
    end

    def enroll_history_clients
      other_provider = described_class.create!(name: "Jordan Lee", email: "jordan@example.test")
      %i[shared exclusive without_entries].each do |label|
        provider.provider_client_relationships.create!(client: clients.fetch(label), plan: "basic")
      end
      other_provider.provider_client_relationships.create!(client: clients.fetch(:shared), plan: "premium")
      other_provider.provider_client_relationships.create!(client: clients.fetch(:unrelated), plan: "basic")
    end

    def capture_select_queries(&block)
      queries = []
      subscriber = lambda do |event|
        payload = event.payload
        queries << payload.fetch(:sql) if payload[:name] != "SCHEMA" && payload.fetch(:sql).match?(/\A\s*SELECT/i)
      end
      ActiveRecord::Base.uncached do
        ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record", &block)
      end
      queries
    end

    context "with entries across shared, exclusive, unrelated and unassigned clients" do
      before do
        enroll_history_clients
        entries
      end

      it "constructs a lazy Active Record relation without fetching client IDs or entries", :aggregate_failures do
        relation = nil
        queries = capture_select_queries { relation = provider.journal_entries.recent_first }

        expect(relation).to be_a(ActiveRecord::Relation)
        expect(relation).not_to be_loaded
        expect(queries).to be_empty
      end

      it "returns each associated entry once in global creation date and ID descending order" do
        expect(provider.journal_entries.recent_first).to eq(
          entries.values_at(:exclusive_newest, :shared_later_tie, :exclusive_earlier_tie, :shared_middle,
                            :shared_oldest)
        )
      end

      it "composes filtering and a limit while preserving global ordering and the provider boundary" do
        relation = provider.journal_entries.recent_first.where(created_at: ..Time.utc(2026, 1, 15)).limit(2)

        expect(relation).to eq(entries.values_at(:shared_later_tie, :exclusive_earlier_tie))
      end

      it "keeps unrelated clients outside an additional client filter" do
        relation = provider.journal_entries.recent_first
                           .where(client_id: clients.values_at(:shared, :unrelated).map(&:id))

        expect(relation).to eq(entries.values_at(:shared_later_tie, :shared_middle, :shared_oldest))
      end

      it "loads all clients' history with one database query that scopes through provider relationships",
         :aggregate_failures do
        queries = capture_select_queries { provider.journal_entries.recent_first.to_a }

        expect(queries.size).to eq(1)
        expect(queries.first).to match(/\bprovider_client_relationships\b/)
      end
    end

    context "when associated clients have no journal entries" do
      before do
        enroll_history_clients
        JournalEntry.create!(client: clients.fetch(:unrelated),
                             content: "An unrelated synthetic journal reflection with at least fifty characters.",
                             created_at: Time.utc(2026, 1, 10))
      end

      it "returns an empty relation that can still be filtered and limited", :aggregate_failures do
        relation = provider.journal_entries.recent_first.where(created_at: ..Time.utc(2026, 1, 15)).limit(2)

        expect(relation).to be_a(ActiveRecord::Relation)
        expect(relation).to be_empty
      end
    end

    context "when the provider has no clients" do
      before do
        entries
        provider
      end

      it "returns an empty relation despite other clients' entries", :aggregate_failures do
        relation = provider.journal_entries.recent_first.where(created_at: ..Time.utc(2026, 1, 30)).limit(2)

        expect(relation).to be_a(ActiveRecord::Relation)
        expect(relation).to be_empty
      end
    end
  end
end
