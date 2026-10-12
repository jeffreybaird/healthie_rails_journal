# frozen_string_literal: true

# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 20_261_008_000_000) do
  create_table "audit_logs", force: :cascade do |t|
    t.string "event", null: false
    t.integer "record_id", null: false
    t.datetime "created_at", null: false
    t.index %w[record_id created_at], name: "index_audit_logs_on_record_id_and_created_at"
  end

  create_table "notes", force: :cascade do |t|
    t.string "title", null: false
    t.datetime "archived_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index %w[archived_at created_at id], name: "index_notes_on_archived_at_and_created_at_and_id"
  end
end
