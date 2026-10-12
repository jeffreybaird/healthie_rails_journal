# frozen_string_literal: true

require "rails_helper"

RSpec.describe JournalEntry, type: :model do
  let(:client) { Client.create!(name: "Sam Rivera", email: "sam@example.test") }
  let(:content) { "  A synthetic journal reflection, with punctuation & <tags>.\nA second line keeps its spacing.  " }
  let(:attributes) { { client: client, content: content } }
  let(:old_timestamp) { Time.utc(2026, 1, 15, 12) }
  let(:existing_entry) { described_class.create!(**attributes, created_at: old_timestamp, updated_at: old_timestamp) }

  describe "persistence" do
    it "round-trips multiline freeform text without trimming or escaping it", :aggregate_failures do
      entry = described_class.create!(attributes)

      expect(described_class.find(entry.id)).to have_attributes(client: client, content: content)
      expect(entry.created_at).to be_present
      expect(entry.updated_at).to be_present
    end

    it "preserves changed text" do
      existing_entry.update!(content: content.reverse)

      expect(existing_entry.reload.content).to eq(content.reverse)
    end

    it "updates the modification timestamp while preserving the creation timestamp", :aggregate_failures do
      existing_entry.update!(content: content.reverse)

      expect(existing_entry.reload.created_at).to eq(old_timestamp)
      expect(existing_entry.updated_at).to be > old_timestamp
    end

    it "allows multiple entries with identical text for one client", :aggregate_failures do
      entries = Array.new(2) { described_class.create!(attributes) }

      expect(client.journal_entries).to match_array(entries)
      expect(entries.map(&:id).uniq.size).to eq(2)
    end
  end

  describe "content validation" do
    it "accepts exactly 50 characters", :aggregate_failures do
      entry = described_class.new(**attributes, content: "x" * 50)

      expect(entry.save).to be(true)
      expect(entry.reload.content).to eq("x" * 50)
    end

    it "rejects 49 characters without persisting", :aggregate_failures do
      entry = described_class.new(**attributes, content: "x" * 49)

      expect(entry.save).to be(false)
      expect(entry.errors.details[:content]).to include(a_hash_including(error: :too_short, count: 50))
      expect(described_class.count).to eq(0)
    end

    [nil, "", " \t\n", " " * 50].each do |blank_content|
      it "rejects blank content #{blank_content.inspect}", :aggregate_failures do
        entry = described_class.new(**attributes, content: blank_content)

        expect(entry.save).to be(false)
        expect(entry.errors.details[:content]).to include(a_hash_including(error: :blank))
        expect(described_class.count).to eq(0)
      end
    end

    it "does not repeat rejected journal text in validation errors", :aggregate_failures do
      private_content = "Synthetic private reflection that is too short."
      entry = described_class.new(**attributes, content: private_content)

      expect(entry.save).to be(false)
      expect(entry.errors.full_messages).not_to be_empty
      expect(entry.errors.full_messages.join).not_to include(private_content)
    end
  end

  describe "client association" do
    it "belongs to a client", :aggregate_failures do
      reflection = described_class.reflect_on_association(:client)

      expect(reflection.macro).to eq(:belongs_to)
      expect(reflection.klass).to eq(Client)
    end

    it "declares the client's direct journal entry collection", :aggregate_failures do
      reflection = Client.reflect_on_association(:journal_entries)

      expect(reflection.macro).to eq(:has_many)
      expect(reflection.klass).to eq(described_class)
    end

    it "rejects a missing client", :aggregate_failures do
      entry = described_class.new(**attributes, client: nil)

      expect(entry.save).to be(false)
      expect(entry.errors[:client]).not_to be_empty
      expect(described_class.count).to eq(0)
    end

    it "rejects a client ID that does not exist", :aggregate_failures do
      entry = described_class.new(content: content, client_id: 999_999)

      expect(entry.save).to be(false)
      expect(entry.errors[:client]).not_to be_empty
      expect(described_class.count).to eq(0)
    end

    it "limits a client's collection to their own entries", :aggregate_failures do
      own_entry = described_class.create!(attributes)
      other_client = Client.create!(name: "Taylor Reed", email: "taylor@example.test")
      other_entry = described_class.create!(client: other_client, content: content)

      expect(client.journal_entries).to eq([own_entry])
      expect(other_client.journal_entries).to eq([other_entry])
    end

    it "returns an empty collection for a client without entries" do
      expect(client.journal_entries).to be_empty
    end
  end

  describe "database constraints" do
    %i[client_id content].each do |column|
      it "rejects null #{column} when validation is bypassed", :aggregate_failures do
        entry = described_class.new(attributes)
        entry.public_send("#{column}=", nil)

        expect { entry.save!(validate: false) }.to raise_error(ActiveRecord::NotNullViolation)
        expect(described_class.count).to eq(0)
      end
    end

    it "enforces the client foreign key when validation is bypassed", :aggregate_failures do
      entry = described_class.new(content: content, client_id: 999_999)

      expect { entry.save!(validate: false) }.to raise_error(ActiveRecord::InvalidForeignKey)
      expect(described_class.count).to eq(0)
    end

    it "prevents deleting a client referenced by a journal entry", :aggregate_failures do
      entry = described_class.create!(attributes)

      expect { client.delete }.to raise_error(ActiveRecord::InvalidForeignKey)
      expect(Client.find(client.id)).to eq(client)
      expect(entry.reload).to be_persisted
    end

    it "has a nonunique index supporting client history and its stable date ordering" do
      indexes = described_class.connection.indexes(described_class.table_name)

      expect(indexes).to include(have_attributes(columns: %w[client_id created_at id], unique: false))
    end

    it "has a nonunique index supporting stable date ordering across clients" do
      indexes = described_class.connection.indexes(described_class.table_name)

      expect(indexes).to include(have_attributes(columns: %w[created_at id], unique: false))
    end
  end
end
