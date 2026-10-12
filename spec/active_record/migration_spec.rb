# frozen_string_literal: true

require "spec_helper"
require "active_record"
require "open3"
require "sqlite3"
require "tmpdir"

RSpec.describe ActiveRecord::Migration do
  it "creates both tables from an empty database with nullable strings and required timestamps", :aggregate_failures do
    with_migrated_database do |database|
      %w[providers clients].each { |table| expect_person_table(database, table) }
    end
  end

  it "creates required relationship columns, foreign keys and lookup indexes from an empty database" do
    with_migrated_database do |database|
      expect_relationship_schema(database)
    end
  end

  def with_migrated_database(&block)
    Dir.mktmpdir("person-record-migrations") do |directory|
      database_path = File.join(directory, "test.sqlite3")
      output, errors, result = Open3.capture3(
        migration_environment(directory, database_path), "bundle", "exec", "rails", "db:migrate",
        chdir: File.expand_path("../..", __dir__)
      )

      expect(result).to be_success, "Fresh database migration failed:\n#{output}\n#{errors}"

      SQLite3::Database.new(database_path, &block)
    end
  end

  def migration_environment(directory, database_path)
    {
      "RAILS_ENV" => "test", "DATABASE_PATH" => database_path,
      "DATABASE_URL" => nil, "PRIMARY_DATABASE_URL" => nil,
      "SCHEMA" => File.join(directory, "schema.rb")
    }
  end

  def expect_person_table(database, table)
    expect(database.table_info(table)).to include(
      a_hash_including("name" => "id", "type" => "integer", "pk" => 1),
      a_hash_including("name" => "name", "type" => "varchar", "notnull" => 0),
      a_hash_including("name" => "email", "type" => "varchar", "notnull" => 0),
      a_hash_including("name" => "created_at", "type" => a_string_starting_with("datetime"), "notnull" => 1),
      a_hash_including("name" => "updated_at", "type" => a_string_starting_with("datetime"), "notnull" => 1)
    )
  end

  def expect_relationship_schema(database)
    database.results_as_hash = true
    aggregate_failures do
      expect_relationship_columns(database)
      expect_relationship_foreign_keys(database)
      expect_relationship_indexes(database)
    end
  end

  def expect_relationship_columns(database)
    expect(database.table_info("provider_client_relationships")).to include(
      a_hash_including("name" => "provider_id", "type" => "integer", "notnull" => 1),
      a_hash_including("name" => "client_id", "type" => "integer", "notnull" => 1),
      a_hash_including("name" => "plan", "type" => "varchar", "notnull" => 1, "dflt_value" => nil),
      a_hash_including("name" => "created_at", "type" => a_string_starting_with("datetime"), "notnull" => 1),
      a_hash_including("name" => "updated_at", "type" => a_string_starting_with("datetime"), "notnull" => 1)
    )
  end

  def expect_relationship_foreign_keys(database)
    keys = database.execute("PRAGMA foreign_key_list(provider_client_relationships)")

    expect(keys.map { |key| key.values_at("from", "table", "to") }).to contain_exactly(
      %w[provider_id providers id], %w[client_id clients id]
    )
  end

  def expect_relationship_indexes(database)
    indexes = database.execute("PRAGMA index_list(provider_client_relationships)").map do |index|
      columns = database.execute("PRAGMA index_info(#{index.fetch("name")})").map { |column| column.fetch("name") }
      { columns: columns, unique: index.fetch("unique") }
    end

    expect(indexes).to contain_exactly(
      { columns: %w[provider_id client_id], unique: 1 },
      { columns: %w[client_id], unique: 0 }
    )
  end
end
