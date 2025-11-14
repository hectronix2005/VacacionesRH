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

ActiveRecord::Schema[8.0].define(version: 2025_11_14_135413) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "areas", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_areas_on_name", unique: true
  end

  create_table "countries", force: :cascade do |t|
    t.string "name", null: false
    t.string "vacation_term", null: false
    t.integer "default_vacation_days", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "working_days", default: {"friday" => true, "monday" => true, "sunday" => false, "tuesday" => true, "saturday" => false, "thursday" => true, "wednesday" => true}
    t.string "g_country"
    t.index ["g_country"], name: "index_countries_on_g_country", unique: true
    t.index ["name"], name: "index_countries_on_name", unique: true
  end

  create_table "solid_cable_messages", force: :cascade do |t|
    t.binary "channel", null: false
    t.binary "payload", null: false
    t.datetime "created_at", null: false
    t.bigint "channel_hash", null: false
    t.index ["channel"], name: "index_solid_cable_messages_on_channel"
    t.index ["channel_hash"], name: "index_solid_cable_messages_on_channel_hash"
    t.index ["created_at"], name: "index_solid_cable_messages_on_created_at"
  end

  create_table "solid_cache_entries", force: :cascade do |t|
    t.binary "key", null: false
    t.binary "value", null: false
    t.datetime "created_at", null: false
    t.bigint "key_hash", null: false
    t.integer "byte_size", null: false
    t.index ["byte_size"], name: "index_solid_cache_entries_on_byte_size"
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash", unique: true
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "concurrency_key", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
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
    t.string "name", null: false
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
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

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "task_key", null: false
    t.datetime "run_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.string "key", null: false
    t.string "schedule", null: false
    t.string "command", limit: 2048
    t.string "class_name"
    t.text "arguments"
    t.string "queue_name"
    t.integer "priority", default: 0
    t.boolean "static", default: true, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
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

  create_table "users", force: :cascade do |t|
    t.string "document_number"
    t.string "phone"
    t.string "name"
    t.string "password_digest"
    t.boolean "active"
    t.bigint "lead_id"
    t.jsonb "roles", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "country_id", null: false
    t.date "hire_date"
    t.string "email"
    t.bigint "area_id"
    t.jsonb "working_days", default: {"friday" => false, "monday" => false, "sunday" => false, "tuesday" => false, "saturday" => false, "thursday" => false, "wednesday" => false}
    t.string "company", default: ""
    t.string "position", default: ""
    t.index ["active", "country_id"], name: "index_users_on_active_and_country_id"
    t.index ["active", "lead_id"], name: "index_users_on_active_and_lead_id"
    t.index ["area_id"], name: "index_users_on_area_id"
    t.index ["country_id"], name: "index_users_on_country_id"
    t.index ["document_number"], name: "index_users_on_document_number", unique: true
    t.index ["lead_id"], name: "index_users_on_lead_id"
  end

  create_table "vacation_approval_configs", force: :cascade do |t|
    t.string "role", null: false
    t.boolean "required", default: true
    t.integer "order_position", default: 0
    t.boolean "active", default: true
    t.text "description"
    t.integer "minimum_approvals", default: 1
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_vacation_approval_configs_on_active"
    t.index ["order_position"], name: "index_vacation_approval_configs_on_order_position"
    t.index ["role"], name: "index_vacation_approval_configs_on_role", unique: true
  end

  create_table "vacation_approvals", force: :cascade do |t|
    t.bigint "vacation_request_id", null: false
    t.bigint "user_id", null: false
    t.string "role", null: false
    t.integer "status", default: 0, null: false
    t.datetime "approved_at"
    t.text "comments"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["approved_at"], name: "index_vacation_approvals_on_approved_at"
    t.index ["user_id"], name: "index_vacation_approvals_on_user_id"
    t.index ["vacation_request_id", "role"], name: "index_vacation_approvals_on_vacation_request_id_and_role", unique: true
    t.index ["vacation_request_id"], name: "index_vacation_approvals_on_vacation_request_id"
  end

  create_table "vacation_balances", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "year", default: 0, null: false
    t.integer "total_days", default: 0, null: false
    t.integer "used_days", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "worked_days", default: 0
    t.integer "days_to_enjoy", default: 0
    t.integer "days_available", default: 0
    t.integer "days_scheduled", default: 0
    t.index ["user_id", "year"], name: "index_vacation_balances_on_user_id_and_year", unique: true
    t.index ["user_id"], name: "index_vacation_balances_on_user_id"
    t.index ["year"], name: "index_vacation_balances_on_year"
  end

  create_table "vacation_requests", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.date "start_date", null: false
    t.date "end_date", null: false
    t.integer "days_requested", null: false
    t.integer "status", default: 0, null: false
    t.text "reason"
    t.bigint "approved_by_id"
    t.datetime "approved_at"
    t.text "rejected_reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "company", default: ""
    t.index ["approved_by_id"], name: "index_vacation_requests_on_approved_by_id"
    t.index ["start_date", "end_date"], name: "index_vacation_requests_on_start_date_and_end_date"
    t.index ["status", "created_at"], name: "index_vacation_requests_on_status_and_created_at"
    t.index ["status"], name: "index_vacation_requests_on_status"
    t.index ["user_id", "start_date"], name: "index_vacation_requests_on_user_id_and_start_date"
    t.index ["user_id", "status", "created_at"], name: "index_vacation_requests_on_user_status_created"
    t.index ["user_id", "status"], name: "index_vacation_requests_on_user_id_and_status"
    t.index ["user_id"], name: "index_vacation_requests_on_user_id"
  end

  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "users", "areas"
  add_foreign_key "users", "countries"
  add_foreign_key "users", "users", column: "lead_id"
  add_foreign_key "vacation_approvals", "users"
  add_foreign_key "vacation_approvals", "vacation_requests"
  add_foreign_key "vacation_balances", "users"
  add_foreign_key "vacation_requests", "users"
  add_foreign_key "vacation_requests", "users", column: "approved_by_id"
end
