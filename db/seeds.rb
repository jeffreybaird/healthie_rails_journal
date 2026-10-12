# frozen_string_literal: true

# Fictional console examples; repeated loads preserve existing records and edits.
relationships = [
  [:alex, :sam, "basic"],
  [:alex, :taylor, "premium"],
  [:jordan, :sam, "premium"],
  [:jordan, :riley, "basic"]
]

# Insert ties in a fixed order so recent_first demonstrates its ID tie-breaker.
entries = [
  ["taylor-newest", :taylor, 20],
  ["sam-oldest", :sam, 5],
  ["taylor-tie", :taylor, 15],
  ["sam-tie-first", :sam, 15],
  ["sam-tie-second", :sam, 15],
  ["sam-middle", :sam, 10],
  ["riley-newest", :riley, 25],
  ["unrelated-newest", :unrelated, 30]
]

ApplicationRecord.transaction do
  providers = { alex: "Alex Sample", jordan: "Jordan Sample" }.to_h do |key, name|
    email = "seed-#{key}@example.test"
    [key, Provider.where("lower(email) = ?", email).first_or_create!(name: name, email: email)]
  end

  clients = { sam: "Sam Sample", taylor: "Taylor Sample", riley: "Riley Sample",
              unrelated: "Unrelated Sample" }.to_h do |key, name|
    email = "seed-#{key}@example.test"
    [key, Client.where("lower(email) = ?", email).first_or_create!(name: name, email: email)]
  end

  relationships.each do |provider, client, plan|
    ProviderClientRelationship.find_or_create_by!(provider: providers.fetch(provider),
                                                  client: clients.fetch(client)) do |relationship|
      relationship.plan = plan
    end
  end

  entries.each do |label, client, day|
    JournalEntry.find_or_create_by!(
      client: clients.fetch(client),
      content: "Synthetic seed entry #{label}: a fictional reflection for query practice.",
      created_at: Time.utc(2026, 1, day)
    )
  end
end
