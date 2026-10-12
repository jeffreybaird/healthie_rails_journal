# frozen_string_literal: true

Given("the following dated journal entries exist in this insertion order:") do |table|
  @dated_journal_entries = table.hashes.to_h do |row|
    label = row.fetch("label")
    timestamp = Time.iso8601(row.fetch("created_at"))
    entry = JournalEntry.create!(
      client: @journal_clients.fetch(row.fetch("client")),
      content: "A synthetic journal reflection with sufficient detail for #{label}.",
      created_at: timestamp, updated_at: timestamp
    )
    [label, entry]
  end
end

When("I retrieve client {string} journal history") do |client_name|
  @journal_history_query = @journal_clients.fetch(client_name).journal_entries.recent_first
end

When("I retrieve client {string} journal history through {string} limited to {int} entries") do |name, cutoff, limit|
  @journal_history_query = @journal_clients.fetch(name).journal_entries.recent_first
                                           .where(created_at: ..Time.iso8601(cutoff)).limit(limit)
end

Then("the journal history query returns an Active Record relation with exactly these entries in order:") do |table|
  expected_entries = table.hashes.map { |row| @dated_journal_entries.fetch(row.fetch("label")) }

  expect(@journal_history_query).to be_a(ActiveRecord::Relation)
  expect(@journal_history_query).to eq(expected_entries)
end

Then("the journal history query returns an empty Active Record relation") do
  expect(@journal_history_query).to be_a(ActiveRecord::Relation)
  expect(@journal_history_query).to be_empty
end
