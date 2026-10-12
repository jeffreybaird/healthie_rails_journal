# frozen_string_literal: true

When("I filter client {string} providers to these names in descending name order:") do |client_name, table|
  names = table.hashes.map { |row| row.fetch("name") }
  @provider_query = @relationship_clients.fetch(client_name).providers.where(name: names).order(name: :desc)
end

Then("the provider query returns an Active Record relation with exactly these providers in order:") do |table|
  expected_providers = table.hashes.map { |row| @relationship_providers.fetch(row.fetch("name")) }

  expect(@provider_query).to be_a(ActiveRecord::Relation)
  expect(@provider_query).to eq(expected_providers)
end

Then("the provider query returns an empty Active Record relation") do
  expect(@provider_query).to be_a(ActiveRecord::Relation)
  expect(@provider_query).to be_empty
end
