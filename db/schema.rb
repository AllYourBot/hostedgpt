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

ActiveRecord::Schema[7.1].define(version: 2023_12_26_160631) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "assistants", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "model"
    t.string "name"
    t.string "description"
    t.string "instructions"
    t.jsonb "tools", default: [], null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_assistants_on_user_id"
  end

  create_table "chats", force: :cascade do |t|
    t.string "name"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_chats_on_user_id"
  end

  create_table "conversations", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "assistant_id", null: false
    t.string "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assistant_id"], name: "index_conversations_on_assistant_id"
    t.index ["user_id"], name: "index_conversations_on_user_id"
  end

  create_table "documents", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "assistant_id"
    t.bigint "message_id"
    t.string "filename", null: false
    t.string "purpose", null: false
    t.integer "bytes", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assistant_id"], name: "index_documents_on_assistant_id"
    t.index ["message_id"], name: "index_documents_on_message_id"
    t.index ["user_id"], name: "index_documents_on_user_id"
  end

  create_table "events", force: :cascade do |t|
    t.uuid "request_id"
    t.string "user_agent"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "conversation_id", null: false
    t.string "role", null: false
    t.string "content_text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "content_document_id"
    t.bigint "run_id"
    t.index ["content_document_id"], name: "index_messages_on_content_document_id"
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
    t.index ["run_id"], name: "index_messages_on_run_id"
  end

  create_table "notes", force: :cascade do |t|
    t.text "content"
    t.bigint "chat_id", null: false
    t.integer "parent_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_id"], name: "index_notes_on_chat_id"
    t.index ["parent_id"], name: "index_notes_on_parent_id"
  end

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

  create_table "runs", force: :cascade do |t|
    t.bigint "assistant_id", null: false
    t.bigint "conversation_id", null: false
    t.string "status", null: false
    t.jsonb "required_action"
    t.jsonb "last_error"
    t.datetime "expired_at", precision: nil, null: false
    t.datetime "started_at", precision: nil
    t.datetime "cancelled_at", precision: nil
    t.datetime "failed_at", precision: nil
    t.datetime "completed_at", precision: nil
    t.string "model", null: false
    t.string "instructions", null: false
    t.string "additional_instructions"
    t.jsonb "tools", default: [], null: false
    t.jsonb "file_ids", default: [], null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assistant_id"], name: "index_runs_on_assistant_id"
    t.index ["conversation_id"], name: "index_runs_on_conversation_id"
  end

  create_table "steps", force: :cascade do |t|
    t.bigint "assistant_id", null: false
    t.bigint "conversation_id", null: false
    t.bigint "run_id", null: false
    t.string "kind", null: false
    t.string "status", null: false
    t.jsonb "details", null: false
    t.jsonb "last_error"
    t.datetime "expired_at", precision: nil
    t.datetime "cancelled_at", precision: nil
    t.datetime "failed_at", precision: nil
    t.datetime "completed_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assistant_id"], name: "index_steps_on_assistant_id"
    t.index ["conversation_id"], name: "index_steps_on_conversation_id"
    t.index ["run_id"], name: "index_steps_on_run_id"
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

  add_foreign_key "assistants", "users"
  add_foreign_key "chats", "users"
  add_foreign_key "conversations", "assistants"
  add_foreign_key "conversations", "users"
  add_foreign_key "documents", "assistants"
  add_foreign_key "documents", "messages"
  add_foreign_key "documents", "users"
  add_foreign_key "messages", "conversations"
  add_foreign_key "messages", "documents", column: "content_document_id"
  add_foreign_key "messages", "runs"
  add_foreign_key "notes", "chats"
  add_foreign_key "runs", "assistants"
  add_foreign_key "runs", "conversations"
  add_foreign_key "steps", "assistants"
  add_foreign_key "steps", "conversations"
  add_foreign_key "steps", "runs"
  add_foreign_key "tasks", "projects"
end
