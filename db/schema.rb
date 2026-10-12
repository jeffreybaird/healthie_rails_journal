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

ActiveRecord::Schema[8.1].define(version: 2026_10_12_000400) do
  create_table "clients", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower(email)", name: "index_clients_on_lower_email", unique: true
  end

  create_table "provider_client_relationships", force: :cascade do |t|
    t.integer "provider_id", null: false
    t.integer "client_id", null: false
    t.string "plan", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_provider_client_relationships_on_client_id"
    t.index ["provider_id", "client_id"], name: "idx_on_provider_id_client_id_28ee6d0de9", unique: true
  end

  create_table "providers", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower(email)", name: "index_providers_on_lower_email", unique: true
  end

  add_foreign_key "provider_client_relationships", "clients"
  add_foreign_key "provider_client_relationships", "providers"
end
