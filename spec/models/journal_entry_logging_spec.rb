# frozen_string_literal: true

require "rails_helper"
require "stringio"

RSpec.describe "Journal entry log privacy", type: :model do
  let(:logs) { capture_sql_logs { persist_private_journal } }

  it "keeps journal text and client details out of actual debug SQL logs", :aggregate_failures do
    expect(logs).to include("INSERT INTO", "clients", "journal_entries", "[FILTERED]")
    expect(logs).not_to include("Synthetic Private Client", "synthetic.private@example.test")
    expect(logs).not_to include("Synthetic confidential journal content.")
  end

  def persist_private_journal
    client = Client.create!(name: "Synthetic Private Client", email: "synthetic.private@example.test")
    entry = JournalEntry.create!(client: client, content: "Synthetic confidential journal content. " * 2)
    expect(entry.reload.content).to eq("Synthetic confidential journal content. " * 2)
  end

  def capture_sql_logs
    original_logger = ActiveRecord::Base.logger
    output = StringIO.new
    ActiveRecord::Base.logger = ActiveSupport::Logger.new(output, level: Logger::DEBUG)
    yield
    output.string
  ensure
    ActiveRecord::Base.logger = original_logger
  end
end
