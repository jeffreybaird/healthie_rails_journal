# frozen_string_literal: true

require "spec_helper"
require "active_record"
require "open3"
require "sqlite3"
require "tmpdir"

RSpec.describe ActiveRecord::Migration do
  it "creates a journal text column, required client foreign key and timestamps from an empty database" do
    with_journal_database do |database, environment|
      expect_journal_migration_success(run_journal_migrations(environment))
      expect_journal_columns(database)
      expect_journal_foreign_key(database)
    end
  end

  it "creates nonunique indexes for client history and stable date ordering" do
    with_journal_database do |database, environment|
      expect_journal_migration_success(run_journal_migrations(environment))
      expect_journal_indexes(database)
    end
  end

  it "preserves existing client rows on upgrade and journal schema rollback", :aggregate_failures do
    with_journal_database do |database, environment|
      expect_preserved_clients(database, environment)
    end
  end

  def with_journal_database
    Dir.mktmpdir("journal-entry-migrations") do |directory|
      database_path = File.join(directory, "test.sqlite3")
      SQLite3::Database.new(database_path) do |database|
        database.results_as_hash = true
        yield database, journal_migration_environment(directory, database_path)
      end
    end
  end

  def journal_migration_environment(directory, database_path)
    {
      "RAILS_ENV" => "test", "DATABASE_PATH" => database_path,
      "DATABASE_URL" => nil, "PRIMARY_DATABASE_URL" => nil,
      "SCHEMA" => File.join(directory, "schema.rb")
    }
  end

  def expect_preserved_clients(database, environment)
    expect_journal_migration_success(run_journal_migrations(environment, "20261012000400"))
    seed_existing_client(database)
    original_clients = database.execute("SELECT * FROM clients ORDER BY id")
    expect_journal_migration_success(run_journal_migrations(environment))
    expect(database.execute("SELECT * FROM clients ORDER BY id")).to eq(original_clients)
    expect(database.execute("PRAGMA foreign_key_check")).to be_empty
    expect_journal_rollback(database, environment, original_clients)
  end

  def expect_journal_rollback(database, environment, original_clients)
    expect_journal_migration_success(run_journal_migrations(environment, "20261012000400"))
    expect(database.execute("SELECT * FROM clients ORDER BY id")).to eq(original_clients)
    expect(database.execute("SELECT name FROM sqlite_master WHERE name = 'journal_entries'")).to be_empty
  end

  def run_journal_migrations(environment, version = nil)
    Open3.capture3(
      environment.merge("VERSION" => version), "bundle", "exec", "rails", "db:migrate",
      chdir: File.expand_path("../..", __dir__)
    )
  end

  def expect_journal_migration_success(result)
    output, errors, status = result

    expect(status).to be_success, "Journal migration failed:\n#{output}\n#{errors}"
  end

  def expect_journal_columns(database)
    expect(database.table_info("journal_entries")).to include(
      a_hash_including("name" => "id", "type" => "integer", "pk" => 1),
      a_hash_including("name" => "content", "type" => a_string_matching(/\Atext\z/i), "notnull" => 1),
      a_hash_including("name" => "client_id", "type" => "integer", "notnull" => 1),
      a_hash_including("name" => "created_at", "type" => a_string_starting_with("datetime"), "notnull" => 1),
      a_hash_including("name" => "updated_at", "type" => a_string_starting_with("datetime"), "notnull" => 1)
    )
  end

  def expect_journal_foreign_key(database)
    keys = database.execute("PRAGMA foreign_key_list(journal_entries)")

    expect(keys.map { |key| key.values_at("from", "table", "to") }).to contain_exactly(%w[client_id clients id])
  end

  def expect_journal_indexes(database)
    indexes = database.execute("PRAGMA index_list(journal_entries)").map do |index|
      columns = database.execute("PRAGMA index_info(#{index.fetch("name")})").map { |column| column.fetch("name") }
      { columns: columns, unique: index.fetch("unique") }
    end

    expect(indexes).to include(
      { columns: %w[client_id created_at id], unique: 0 },
      { columns: %w[created_at id], unique: 0 }
    )
  end

  def seed_existing_client(database)
    database.execute(
      "INSERT INTO clients (id, name, email, created_at, updated_at) VALUES (?, ?, ?, ?, ?)",
      [21, "Synthetic Existing Client", "existing@example.test", "2026-01-15 12:00:00", "2026-01-15 12:00:00"]
    )
  end
end
