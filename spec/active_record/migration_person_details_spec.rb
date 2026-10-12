# frozen_string_literal: true

require "spec_helper"
require "active_record"
require "active_support/core_ext/enumerable"
require "open3"
require "sqlite3"
require "tmpdir"

RSpec.describe ActiveRecord::Migration do
  it "upgrades valid existing people without changing rows, IDs or relationship foreign keys" do
    with_legacy_people_database do |database, environment|
      expect_valid_upgrade(database, environment)
    end
  end

  it "restores nullable, nonunique person details on rollback while preserving rows and relationships" do
    with_legacy_people_database do |database, environment|
      expect_valid_rollback(database, environment)
    end
  end

  %w[providers clients].each do |table|
    {
      "null name" => { name: nil }, "blank name" => { name: "" }, "whitespace name" => { name: " \t\n" },
      "null email" => { email: nil }, "blank email" => { email: "" }, "whitespace email" => { email: " \t\n" },
      "malformed email" => { email: "unformatted-email" },
      "case-insensitive duplicate email" => { email: "SHARED@EXAMPLE.TEST" }
    }.each do |description, invalid_attributes|
      it "rejects existing #{table} with #{description} without revealing or changing their data" do
        with_legacy_people_database do |database, environment|
          insert_legacy_person(database, table, **invalid_attributes)
          expect_rejected_upgrade(database, environment)
        end
      end
    end
  end

  def with_legacy_people_database
    Dir.mktmpdir("person-details-migration") do |directory|
      database_path = File.join(directory, "test.sqlite3")
      environment = isolated_migration_environment(directory, database_path)
      expect_migration_success(run_people_migration(environment, "20261012000300"))
      SQLite3::Database.new(database_path) do |database|
        database.results_as_hash = true
        seed_legacy_people(database)
        yield database, environment
      end
    end
  end

  def isolated_migration_environment(directory, database_path)
    {
      "RAILS_ENV" => "test", "DATABASE_PATH" => database_path,
      "DATABASE_URL" => nil, "PRIMARY_DATABASE_URL" => nil,
      "SCHEMA" => File.join(directory, "schema.rb")
    }
  end

  def run_people_migration(environment, version = nil)
    Open3.capture3(
      environment.merge("VERSION" => version), "bundle", "exec", "rails", "db:migrate",
      chdir: File.expand_path("../..", __dir__)
    )
  end

  def expect_migration_success(result)
    output, errors, status = result

    expect(status).to be_success, "Migration failed:\n#{output}\n#{errors}"
  end

  def seed_legacy_people(database)
    %w[providers clients].each do |table|
      insert_legacy_person(database, table, id: 11, name: "Private Existing Person", email: "shared@example.test")
    end
    seed_legacy_relationship(database)
  end

  def seed_legacy_relationship(database)
    timestamp = "2026-01-15 12:00:00"
    database.execute(
      "INSERT INTO provider_client_relationships (id, provider_id, client_id, plan, created_at, updated_at) " \
      "VALUES (?, ?, ?, ?, ?, ?)", [31, 11, 11, "premium", timestamp, timestamp]
    )
  end

  def insert_legacy_person(database, table, id: 12, **attributes)
    person = { name: "Private Invalid Person", email: "private.invalid@example.test" }.merge(attributes)
    database.execute(
      "INSERT INTO #{table} (id, name, email, created_at, updated_at) VALUES (?, ?, ?, ?, ?)",
      [id, person.fetch(:name), person.fetch(:email), "2026-01-15 12:00:00", "2026-01-15 12:00:00"]
    )
  end

  def person_rows(database)
    %w[providers clients provider_client_relationships].index_with do |table|
      database.execute("SELECT * FROM #{table} ORDER BY id")
    end
  end

  def person_schema(database)
    database.execute("SELECT name, sql FROM sqlite_master WHERE name NOT LIKE 'sqlite_%' ORDER BY name")
  end

  def expect_valid_upgrade(database, environment)
    before = person_rows(database)
    expect_migration_success(run_people_migration(environment))
    aggregate_failures do
      expect(person_rows(database)).to eq(before)
      expect(database.execute("PRAGMA foreign_key_check")).to be_empty
      %w[providers clients].each { |table| expect_required_person_schema(database, table) }
    end
  end

  def expect_required_person_schema(database, table)
    columns = database.table_info(table)
    expect(columns).to include(
      a_hash_including("name" => "name", "notnull" => 1),
      a_hash_including("name" => "email", "notnull" => 1)
    )
    indexes = database.execute("PRAGMA index_list(#{table})")
    expect(indexes).to include(a_hash_including("unique" => 1))
    expect_database_email_uniqueness(database, table)
  end

  def expect_database_email_uniqueness(database, table)
    expect { insert_legacy_person(database, table, email: "SHARED@EXAMPLE.TEST") }
      .to raise_error(SQLite3::ConstraintException)
  end

  def expect_valid_rollback(database, environment)
    before = person_rows(database)
    expect_migration_success(run_people_migration(environment))
    expect_migration_success(run_people_migration(environment, "20261012000300"))
    aggregate_failures do
      expect(person_rows(database)).to eq(before)
      expect(database.execute("PRAGMA foreign_key_check")).to be_empty
      %w[providers clients].each { |table| expect_legacy_person_schema(database, table) }
    end
  end

  def expect_legacy_person_schema(database, table)
    expect(database.table_info(table)).to include(
      a_hash_including("name" => "name", "notnull" => 0),
      a_hash_including("name" => "email", "notnull" => 0)
    )
    expect(database.execute("PRAGMA index_list(#{table})")).not_to include(a_hash_including("unique" => 1))
    expect_legacy_person_writes(database, table)
  end

  def expect_legacy_person_writes(database, table)
    insert_legacy_person(database, table, name: nil, email: nil)
    database.execute("UPDATE #{table} SET email = ? WHERE id = ?", ["SHARED@EXAMPLE.TEST", 12])
    expect(database.execute("SELECT id FROM #{table} ORDER BY id").map { |row| row.fetch("id") }).to eq([11, 12])
  end

  def expect_rejected_upgrade(database, environment)
    before_rows = person_rows(database)
    before_schema = person_schema(database)
    output, errors, status = run_people_migration(environment)
    aggregate_failures do
      expect_rejected_migration_result(output, errors, status)
      expect_unchanged_people_database(database, before_rows, before_schema)
    end
  end

  def expect_rejected_migration_result(output, errors, status)
    expect(status).not_to be_success
    expect("#{output}\n#{errors}").to match(/invalid.*(?:records|data)/i)
    expect_private_values_absent("#{output}\n#{errors}")
  end

  def expect_unchanged_people_database(database, before_rows, before_schema)
    expect(person_rows(database)).to eq(before_rows)
    expect(person_schema(database)).to eq(before_schema)
    expect(database.execute("PRAGMA foreign_key_check")).to be_empty
  end

  def expect_private_values_absent(output)
    ["Private Existing Person", "Private Invalid Person", "shared@example.test",
     "private.invalid@example.test", "SHARED@EXAMPLE.TEST", "unformatted-email"].each do |private_value|
      expect(output).not_to include(private_value)
    end
  end
end
