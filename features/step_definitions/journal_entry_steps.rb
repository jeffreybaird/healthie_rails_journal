# frozen_string_literal: true

# Model-only acceptance steps; journal entry routes are not part of this foundation.
module JournalEntrySteps
  def attempt_journal_entry(attributes)
    @journal_count_before = JournalEntry.count
    @original_journal_text = attributes[:content]
    @attempted_journal_entry = JournalEntry.new(attributes)
    @journal_saved = @attempted_journal_entry.save
    return unless @journal_saved

    @recorded_journals[@attempted_journal_entry.client.name] << @attempted_journal_entry
  end
end

World(JournalEntrySteps)

Given("the following journal clients exist:") do |table|
  @journal_clients = table.hashes.each_with_index.to_h do |row, index|
    [row.fetch("name"), Client.create!(name: row.fetch("name"), email: "journal-client#{index}@example.test")]
  end
  @recorded_journals = Hash.new { |entries, name| entries[name] = [] }
end

When("client {string} records this journal entry:") do |client_name, content|
  attempt_journal_entry(client: @journal_clients.fetch(client_name), content: content)
end

When("client {string} records a journal entry with {int} characters") do |client_name, length|
  attempt_journal_entry(client: @journal_clients.fetch(client_name), content: "x" * length)
end

When("client {string} records a journal entry with {word} text") do |client_name, text_kind|
  content = { "missing" => nil, "empty" => "", "whitespace" => " " * 50 }.fetch(text_kind)
  attempt_journal_entry(client: @journal_clients.fetch(client_name), content: content)
end

When("a journal entry is recorded with a {word} client") do |client_kind|
  client_id = { "missing" => nil, "nonexistent" => 999_999 }.fetch(client_kind)
  attempt_journal_entry(client_id: client_id,
                        content: "A synthetic journal reflection that has at least fifty characters.")
end

Then("the journal entry is stored for client {string} with its original text") do |client_name|
  expect(@journal_saved).to be(true)
  expect(JournalEntry.find(@attempted_journal_entry.id)).to have_attributes(
    client: @journal_clients.fetch(client_name), content: @original_journal_text
  )
  expect(JournalEntry.count).to eq(@journal_count_before + 1)
end

Then("the journal entry has creation and update timestamps") do
  entry = JournalEntry.find(@attempted_journal_entry.id)

  expect(entry.created_at).to be_present
  expect(entry.updated_at).to be_present
end

Then("client {string} has exactly their {int} recorded journal entries") do |client_name, count|
  expected_entries = @recorded_journals.fetch(client_name)

  expect(expected_entries.size).to eq(count)
  expect(@journal_clients.fetch(client_name).journal_entries).to contain_exactly(*expected_entries)
end

Then("the journal entry is rejected without adding a record") do
  expect(@journal_saved).to be(false)
  expect(@attempted_journal_entry).not_to be_persisted
  expect(@attempted_journal_entry.errors).not_to be_empty
  expect(JournalEntry.count).to eq(@journal_count_before)
end
