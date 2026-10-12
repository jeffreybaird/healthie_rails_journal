# frozen_string_literal: true

# Expected synthetic records, shared by the seed specifications and features.
module SampleSeedContract
  PROVIDERS = { alex: "Alex Sample", jordan: "Jordan Sample" }.freeze
  CLIENTS = { sam: "Sam Sample", taylor: "Taylor Sample", riley: "Riley Sample",
              unrelated: "Unrelated Sample" }.freeze
  ENTRIES = [
    ["taylor-newest", :taylor, 20],
    ["sam-oldest", :sam, 5],
    ["taylor-tie", :taylor, 15],
    ["sam-tie-first", :sam, 15],
    ["sam-tie-second", :sam, 15],
    ["sam-middle", :sam, 10],
    ["riley-newest", :riley, 25],
    ["unrelated-newest", :unrelated, 30]
  ].freeze

  def load_sample_seeds
    raise "Sample seed tests require the isolated test environment" unless Rails.env.test?

    load Rails.root.join("db/seeds.rb")
  end

  def seed_provider(key)
    Provider.find_by!(email: "seed-#{key}@example.test")
  end

  def seed_client(key)
    Client.find_by!(email: "seed-#{key}@example.test")
  end

  def seed_content(label)
    "Synthetic seed entry #{label}: a fictional reflection for query practice."
  end

  def seed_entry(label)
    JournalEntry.find_by!(content: seed_content(label))
  end

  def seed_entries(labels)
    labels.map { |label| seed_entry(label) }
  end

  def seed_relationship_rows
    ProviderClientRelationship.includes(:provider, :client).map do |relationship|
      [relationship.provider.email, relationship.client.email, relationship.plan]
    end
  end

  def seed_journal_rows
    JournalEntry.includes(:client).order(:id).map { |entry| [entry.client.email, entry.content, entry.created_at] }
  end

  def customize_seed_records
    provider = seed_provider(:alex)
    provider.update!(name: "Customized Provider")
    client = seed_client(:sam)
    client.update!(name: "Customized Client")
    relationship = ProviderClientRelationship.find_by!(provider: provider, client: client)
    relationship.update!(plan: "premium")
    entry = seed_entry("sam-oldest")
    entry.update!(content: "An edited fictional seed note that must survive repeated sample loads.")
    [provider, client, relationship, entry]
  end

  def reloaded_seed_attributes(records)
    records.map { |record| record.reload.attributes }
  end

  def seed_database_snapshot
    [Provider, Client, ProviderClientRelationship, JournalEntry].to_h do |model|
      [model.name, model.order(:id).map(&:attributes)]
    end
  end
end
