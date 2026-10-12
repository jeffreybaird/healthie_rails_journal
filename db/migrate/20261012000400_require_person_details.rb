# frozen_string_literal: true

require "uri"

# Requires existing person details without changing their stored values.
class RequirePersonDetails < ActiveRecord::Migration[8.1]
  PERSON_TABLES = %i[providers clients].freeze

  def up
    verify_existing_people!

    PERSON_TABLES.each do |table|
      change_column_null table, :name, false
      change_column_null table, :email, false
      add_index table, "lower(email)", unique: true, name: email_index_name(table)
    end
  end

  def down
    PERSON_TABLES.each do |table|
      remove_index table, name: email_index_name(table)
      change_column_null table, :name, true
      change_column_null table, :email, true
    end
  end

  private

  def verify_existing_people!
    PERSON_TABLES.each do |table|
      next unless invalid_details?(table) || duplicate_emails?(table)

      raise ActiveRecord::MigrationError,
            "Invalid person records; resolve required details and duplicate emails before retrying."
    end
  end

  def invalid_details?(table)
    connection.select_rows("SELECT name, email FROM #{connection.quote_table_name(table)}").any? do |name, email|
      name.blank? || email.blank? || !URI::MailTo::EMAIL_REGEXP.match?(email)
    end
  end

  def duplicate_emails?(table)
    connection.select_value(<<~SQL.squish).present?
      SELECT 1 FROM #{connection.quote_table_name(table)}
      GROUP BY lower(email) HAVING COUNT(*) > 1 LIMIT 1
    SQL
  end

  def email_index_name(table)
    "index_#{table}_on_lower_email"
  end
end
