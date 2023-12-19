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

ActiveRecord::Schema[7.1].define(version: 2023_12_19_014006) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "people", force: :cascade do |t|
    t.string "personable_type"
    t.bigint "personable_id"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["personable_type", "personable_id"], name: "index_people_on_personable"
  end

  create_table "projects", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tasks", force: :cascade do |t|
    t.string "title"
    t.boolean "completed", default: false
    t.bigint "project_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_tasks_on_project_id"
  end

  create_table "tombstones", force: :cascade do |t|
    t.datetime "erected_at"
  end

  create_table "users", force: :cascade do |t|
    t.string "password_digest"
    t.datetime "registered_at", default: -> { "CURRENT_TIMESTAMP" }
  end

  add_foreign_key "tasks", "projects"
end
