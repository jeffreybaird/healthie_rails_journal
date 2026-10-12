# frozen_string_literal: true

# Permanently removes the retired generated example's stored data.
class RemoveNotesExample < ActiveRecord::Migration[8.1]
  def up
    drop_table :notes, if_exists: true
    drop_table :audit_logs, if_exists: true
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Removed Notes and audit data cannot be restored by rollback"
  end
end
