# frozen_string_literal: true

# Establishes the content and minimal durable audit tables.
class CreateNotes < ActiveRecord::Migration[8.1]
  def change
    create_notes
    create_audit_logs
  end

  private

  def create_notes
    create_table :notes do |table|
      table.string :title, null: false
      table.datetime :archived_at
      table.timestamps
    end
    add_index :notes, %i[archived_at created_at id]
  end

  def create_audit_logs
    create_table :audit_logs do |table|
      table.string :event, null: false
      table.integer :record_id, null: false
      table.datetime :created_at, null: false
    end
    add_index :audit_logs, %i[record_id created_at]
  end
end
