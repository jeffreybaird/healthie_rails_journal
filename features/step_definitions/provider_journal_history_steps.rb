# frozen_string_literal: true

Given("the following journal provider-client relationships exist:") do |table|
  table.hashes.each do |row|
    ProviderClientRelationship.create!(
      provider: @relationship_providers.fetch(row.fetch("provider")),
      client: @journal_clients.fetch(row.fetch("client")), plan: row.fetch("plan")
    )
  end
end

When("I retrieve provider {string} journal history") do |provider_name|
  @journal_history_query = @relationship_providers.fetch(provider_name).journal_entries.recent_first
end

When("I retrieve provider {string} journal history through {string} limited to {int} entries") do |name, cutoff, limit|
  @journal_history_query = @relationship_providers.fetch(name).journal_entries.recent_first
                                                  .where(created_at: ..Time.iso8601(cutoff)).limit(limit)
end
