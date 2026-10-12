# frozen_string_literal: true

require_relative "../../spec/support/sample_seed_contract"

World(SampleSeedContract)

Given("I load the synthetic sample seeds") do
  load_sample_seeds
end

When("I load the synthetic sample seeds again") do
  load_sample_seeds
end

When("I query sample provider {string} clients") do |key|
  @sample_relation = seed_provider(key).clients.order(:email)
end

When("I query sample client {string} providers") do |key|
  @sample_relation = seed_client(key).providers.order(:email)
end

When("I query sample client {string} journal history") do |key|
  @sample_relation = seed_client(key).journal_entries.recent_first
end

When("I query sample provider {string} journal history") do |key|
  @sample_relation = seed_provider(key).journal_entries.recent_first
end

Then("the sample relation contains exactly these clients:") do |table|
  expect(@sample_relation).to be_a(ActiveRecord::Relation)
  expect(@sample_relation).to eq(table.hashes.map { |row| seed_client(row.fetch("key")) })
end

Then("the sample relation contains exactly these providers:") do |table|
  expect(@sample_relation).to be_a(ActiveRecord::Relation)
  expect(@sample_relation).to eq(table.hashes.map { |row| seed_provider(row.fetch("key")) })
end

Then("the sample relation contains exactly these entries in order:") do |table|
  expect(@sample_relation).to be_a(ActiveRecord::Relation)
  expect(@sample_relation).to eq(table.hashes.map { |row| seed_entry(row.fetch("label")) })
end

Then("the sample relation is empty") do
  expect(@sample_relation).to be_a(ActiveRecord::Relation)
  expect(@sample_relation).to be_empty
end

Then("sample client {string} has plan {string} with {string} and {string} with {string}") do |client, plan, provider,
                                                                                        other_plan, other_provider|
  owner = seed_client(client)
  expect(ProviderClientRelationship.find_by!(client: owner, provider: seed_provider(provider)).plan).to eq(plan)
  expect(ProviderClientRelationship.find_by!(client: owner,
                                             provider: seed_provider(other_provider)).plan).to eq(other_plan)
end

Given("I remember the sample database records") do
  @sample_snapshot = seed_database_snapshot
end

Then("all remembered database records are unchanged") do
  expect(seed_database_snapshot).to eq(@sample_snapshot)
end

Given("I customize a sample provider, client, plan and journal entry") do
  @customized_sample_records = customize_seed_records
  @customized_sample_attributes = @customized_sample_records.map(&:attributes)
end

Then("the customized records retain all their stored attributes") do
  expect(reloaded_seed_attributes(@customized_sample_records)).to eq(@customized_sample_attributes)
end

Then("the original synthetic journal entry is restored as a separate record") do
  expect(seed_entry("sam-oldest").id).not_to eq(@customized_sample_records.last.id)
  expect(JournalEntry.count).to eq(9)
end
