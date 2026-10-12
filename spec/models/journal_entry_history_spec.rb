# frozen_string_literal: true

require "rails_helper"

RSpec.describe JournalEntry, type: :model do
  describe ".recent_first through a client's journal entries" do
    let(:client) { Client.create!(name: "Sam Rivera", email: "sam@example.test") }
    let(:other_client) { Client.create!(name: "Taylor Reed", email: "taylor@example.test") }
    let(:entries) do
      [
        [:newest, client, Time.utc(2026, 1, 20)],
        [:oldest, client, Time.utc(2026, 1, 10)],
        [:earlier_tie, client, Time.utc(2026, 1, 15)],
        [:later_tie, client, Time.utc(2026, 1, 15)],
        [:unrelated_newest, other_client, Time.utc(2026, 1, 25)],
        [:unrelated_tie, other_client, Time.utc(2026, 1, 15)]
      ].to_h do |label, owner, timestamp|
        entry = described_class.create!(
          client: owner, content: "A synthetic journal reflection with sufficient detail for #{label}.",
          created_at: timestamp, updated_at: Time.utc(2026, 2, 1)
        )
        [label, entry]
      end
    end

    context "with entries inserted out of date order" do
      before { entries }

      it "returns a lazy Active Record relation", :aggregate_failures do
        relation = client.journal_entries.recent_first

        expect(relation).to be_a(ActiveRecord::Relation)
        expect(relation).not_to be_loaded
      end

      it "returns every client entry by creation date descending, then ID descending" do
        expect(client.journal_entries.recent_first).to eq(
          entries.values_at(:newest, :later_tie, :earlier_tie, :oldest)
        )
      end

      it "composes filtering and a limit while preserving ordering and the client boundary" do
        relation = client.journal_entries.recent_first.where(created_at: ..Time.utc(2026, 1, 15)).limit(2)

        expect(relation).to eq(entries.values_at(:later_tie, :earlier_tie))
      end
    end

    context "when the client has no entries" do
      before do
        described_class.create!(client: other_client,
                                content: "An unrelated synthetic journal reflection with at least fifty characters.",
                                created_at: Time.utc(2026, 1, 10))
      end

      it "returns an empty Active Record relation that can still be filtered and limited", :aggregate_failures do
        relation = client.journal_entries.recent_first.where(created_at: ..Time.utc(2026, 1, 15)).limit(2)

        expect(relation).to be_a(ActiveRecord::Relation)
        expect(relation).to be_empty
      end
    end
  end
end
