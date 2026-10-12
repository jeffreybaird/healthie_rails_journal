# frozen_string_literal: true

# Model-only acceptance steps for provider-specific plans and associations.
module ProviderClientRelationshipSteps
  def attempt_enrollment(attributes)
    @relationship_count_before = ProviderClientRelationship.count
    @attempted_relationship = ProviderClientRelationship.new(attributes)
    @enrollment_saved = @attempted_relationship.save
  end

  def enrollment_for(provider_name, client_name)
    ProviderClientRelationship.find_by!(
      provider: @relationship_providers.fetch(provider_name),
      client: @relationship_clients.fetch(client_name)
    )
  end
end

World(ProviderClientRelationshipSteps)

Given("the following relationship providers exist:") do |table|
  @relationship_providers = table.hashes.each_with_index.to_h do |row, index|
    [row.fetch("name"), Provider.create!(name: row.fetch("name"), email: "provider#{index}@example.test")]
  end
end

Given("the following relationship clients exist:") do |table|
  @relationship_clients = table.hashes.each_with_index.to_h do |row, index|
    [row.fetch("name"), Client.create!(name: row.fetch("name"), email: "client#{index}@example.test")]
  end
end

When("provider {string} enrolls client {string} on the {string} plan") do |provider_name, client_name, plan|
  attempt_enrollment(
    provider: @relationship_providers.fetch(provider_name),
    client: @relationship_clients.fetch(client_name), plan: plan
  )
end

When("provider {string} enrolls client {string} without a plan") do |provider_name, client_name|
  attempt_enrollment(
    provider: @relationship_providers.fetch(provider_name),
    client: @relationship_clients.fetch(client_name)
  )
end

When("I enroll a client on the {string} plan without a {word}") do |plan, participant|
  attributes = {
    provider: @relationship_providers.fetch("Alex Morgan"),
    client: @relationship_clients.fetch("Sam Rivera"), plan: plan
  }
  attempt_enrollment(attributes.except(participant.to_sym))
end

Then("the enrollment is stored with the {string} plan") do |plan|
  expect(@enrollment_saved).to be(true)
  expect(ProviderClientRelationship.find(@attempted_relationship.id)).to have_attributes(
    provider: @attempted_relationship.provider, client: @attempted_relationship.client, plan: plan
  )
  expect(ProviderClientRelationship.count).to eq(@relationship_count_before + 1)
end

Then("the enrollment is rejected without adding a relationship") do
  expect(@enrollment_saved).to be(false)
  expect(@attempted_relationship).not_to be_persisted
  expect(@attempted_relationship.errors).not_to be_empty
  expect(ProviderClientRelationship.count).to eq(@relationship_count_before)
end

Then("client {string} has the {string} plan with provider {string}") do |client_name, plan, provider_name|
  expect(enrollment_for(provider_name, client_name).plan).to eq(plan)
end

Then("provider {string} has exactly these clients:") do |provider_name, table|
  expected_clients = table.hashes.map { |row| @relationship_clients.fetch(row.fetch("name")) }

  expect(@relationship_providers.fetch(provider_name).clients).to contain_exactly(*expected_clients)
end

Then("client {string} has exactly these providers:") do |client_name, table|
  expected_providers = table.hashes.map { |row| @relationship_providers.fetch(row.fetch("name")) }

  expect(@relationship_clients.fetch(client_name).providers).to contain_exactly(*expected_providers)
end

When("I filter provider {string} clients to these names in descending name order:") do |provider_name, table|
  names = table.hashes.map { |row| row.fetch("name") }
  @client_query = @relationship_providers.fetch(provider_name).clients.where(name: names).order(name: :desc)
end

Then("the client query returns an Active Record relation with exactly these clients in order:") do |table|
  expected_clients = table.hashes.map { |row| @relationship_clients.fetch(row.fetch("name")) }

  expect(@client_query).to be_a(ActiveRecord::Relation)
  expect(@client_query).to eq(expected_clients)
end

Then("the client query returns an empty Active Record relation") do
  expect(@client_query).to be_a(ActiveRecord::Relation)
  expect(@client_query).to be_empty
end
