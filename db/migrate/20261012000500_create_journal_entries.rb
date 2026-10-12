# frozen_string_literal: true

# Creates client journal entries with indexes for stable date ordering.
class CreateJournalEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :journal_entries do |t|
      t.references :client, null: false, foreign_key: true, index: false
      t.text :content, null: false

      t.timestamps
    end

    add_index :journal_entries, %i[client_id created_at id]
    add_index :journal_entries, %i[created_at id]
  end
end
