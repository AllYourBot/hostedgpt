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

ActiveRecord::Schema[7.1].define(version: 2024_04_01_213532) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end
  
  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "assistants", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "model"
    t.string "name"
    t.string "description"
    t.string "instructions"
    t.jsonb "tools", default: [], null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "images", default: false, null: false
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
    t.index ["updated_at"], name: "index_conversations_on_updated_at"
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

  create_table "messages", force: :cascade do |t|
    t.bigint "conversation_id", null: false
    t.string "role", null: false
    t.string "content_text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "content_document_id"
    t.bigint "run_id"
    t.bigint "assistant_id", null: false
    t.datetime "rerequested_at"
    t.datetime "cancelled_at"
    t.datetime "processed_at", precision: nil
    t.index ["assistant_id"], name: "index_messages_on_assistant_id"
    t.index ["content_document_id"], name: "index_messages_on_content_document_id"
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
    t.index ["run_id"], name: "index_messages_on_run_id"
    t.index ["updated_at"], name: "index_messages_on_updated_at"
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

  create_table "replies", force: :cascade do |t|
    t.text "content"
    t.bigint "note_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["note_id"], name: "index_replies_on_note_id"
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
    t.string "instructions"
    t.string "additional_instructions"
    t.jsonb "tools", default: [], null: false
    t.jsonb "file_ids", default: [], null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assistant_id"], name: "index_runs_on_assistant_id"
    t.index ["conversation_id"], name: "index_runs_on_conversation_id"
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "concurrency_key", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "queue_name", null: false
    t.string "class_name", null: false
    t.text "arguments"
    t.integer "priority", default: 0, null: false
    t.string "active_job_id"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.string "queue_name", null: false
    t.datetime "created_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.bigint "supervisor_id"
    t.integer "pid", null: false
    t.string "hostname"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "scheduled_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.string "key", null: false
    t.integer "value", default: 1, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
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

  create_table "tombstones", force: :cascade do |t|
    t.datetime "erected_at"
  end

  create_table "users", force: :cascade do |t|
    t.string "password_digest"
    t.datetime "registered_at", default: -> { "CURRENT_TIMESTAMP" }
    t.string "first_name", null: false
    t.string "last_name"
    t.string "openai_key"
    t.string "anthropic_key"
    t.jsonb "preferences"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "assistants", "users"
  add_foreign_key "chats", "users"
  add_foreign_key "conversations", "assistants"
  add_foreign_key "conversations", "users"
  add_foreign_key "documents", "assistants"
  add_foreign_key "documents", "messages"
  add_foreign_key "documents", "users"
  add_foreign_key "messages", "assistants"
  add_foreign_key "messages", "conversations"
  add_foreign_key "messages", "documents", column: "content_document_id"
  add_foreign_key "messages", "runs"
  add_foreign_key "notes", "chats"
  add_foreign_key "replies", "notes"
  add_foreign_key "runs", "assistants"
  add_foreign_key "runs", "conversations"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "steps", "assistants"
  add_foreign_key "steps", "conversations"
  add_foreign_key "steps", "runs"
end
