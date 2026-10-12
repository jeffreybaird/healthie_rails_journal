# frozen_string_literal: true

require "rails_helper"
require "tmpdir"

RSpec.describe "RemoveNotesExample", :aggregate_failures, :commit do
  let(:connection) { ActiveRecord::Tasks::DatabaseTasks.migration_connection }
  let(:cleanup_version) { 20_261_012_000_000 }
  let(:migration_context) do
    ActiveRecord::MigrationContext.new(
      Rails.root.join("db/migrate").to_s,
      connection.pool.schema_migration,
      connection.pool.internal_metadata
    )
  end

  around do |example|
    Dir.mktmpdir("notes-migration-spec") do |directory|
      configuration = { adapter: "sqlite3", database: File.join(directory, "isolated.sqlite3") }
      ActiveRecord::Tasks::DatabaseTasks.with_temporary_connection(configuration) { example.run }
    end
  end

  context "with populated legacy tables and unrelated data" do
    before do
      create_notes_table
      create_audit_table
      create_unrelated_data
      record_legacy_history
    end

    it "removes both legacy tables while preserving unrelated rows, columns and migration history" do
      migration_context.migrate(cleanup_version)

      expect_cleanup_preserves_unrelated_data
    end

    it "can run cleanup again when the tables are already absent" do
      migration_context.migrate(cleanup_version)
      cleanup = migration_context.migrations.find { |migration| migration.version == cleanup_version }
      cleanup.migrate(:up)

      expect_cleanup_preserves_unrelated_data
    end

    it "rejects rollback explicitly while retaining unrelated data and applied migration history" do
      migration_context.migrate(cleanup_version)

      expect { migration_context.rollback }.to raise_error(StandardError) do |error|
        expect(error.cause).to be_a(ActiveRecord::IrreversibleMigration)
      end
      expect_cleanup_preserves_unrelated_data
    end
  end

  context "with only the notes table remaining" do
    before do
      create_notes_table
      record_legacy_history
    end

    it "removes the remaining legacy table without requiring audit_logs" do
      migration_context.migrate(cleanup_version)

      expect(connection.tables).not_to include("notes", "audit_logs")
    end
  end

  context "with only the audit_logs table remaining" do
    before do
      create_audit_table
      record_legacy_history
    end

    it "removes the remaining legacy table without requiring notes" do
      migration_context.migrate(cleanup_version)

      expect(connection.tables).not_to include("notes", "audit_logs")
    end
  end

  def create_notes_table
    connection.create_table(:notes) do |table|
      table.string :title, null: false
      table.datetime :archived_at
      table.timestamps
    end
    connection.execute(<<~SQL.squish)
      INSERT INTO notes (title, created_at, updated_at)
      VALUES ('Synthetic note', '2026-10-08', '2026-10-08')
    SQL
  end

  def create_audit_table
    connection.create_table(:audit_logs) do |table|
      table.string :event, null: false
      table.integer :record_id, null: false
      table.datetime :created_at, null: false
    end
    connection.execute(<<~SQL.squish)
      INSERT INTO audit_logs (event, record_id, created_at)
      VALUES ('notes.created', 1, '2026-10-08')
    SQL
  end

  def create_unrelated_data
    connection.create_table(:interview_records) { |table| table.string :label, null: false }
    connection.execute("INSERT INTO interview_records (label) VALUES ('Synthetic interview record')")
  end

  def record_legacy_history
    migration_context.schema_migration.create_table
    migration_context.schema_migration.create_version("20260901000000")
    migration_context.schema_migration.create_version("20261008000000")
  end

  def expect_cleanup_preserves_unrelated_data
    expect(connection.tables).not_to include("notes", "audit_logs")
    expect(migration_context.get_all_versions).to contain_exactly(
      20_260_901_000_000, 20_261_008_000_000, cleanup_version
    )
    expect_unrelated_record_preserved
  end

  def expect_unrelated_record_preserved
    expect(connection.select_values("SELECT label FROM interview_records")).to eq(["Synthetic interview record"])
    expect(connection.columns(:interview_records).map(&:name)).to eq(%w[id label])
  end
end
