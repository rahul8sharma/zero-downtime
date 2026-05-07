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

ActiveRecord::Schema[7.1].define(version: 2026_05_07_133908) do
  create_table "activities", force: :cascade do |t|
    t.string "action"
    t.integer "project_id"
    t.text "details"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_activities_on_project_id"
  end

  create_table "incidents", force: :cascade do |t|
    t.string "title"
    t.string "severity"
    t.string "status"
    t.text "error_message"
    t.text "stack_trace"
    t.string "service"
    t.string "source"
    t.string "datadog_id"
    t.integer "project_id", null: false
    t.datetime "last_synced_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_incidents_on_project_id"
  end

  create_table "projects", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "github_uid"
    t.string "github_token"
    t.string "github_repo_url"
    t.string "github_username"
    t.string "datadog_api_key"
    t.string "datadog_app_key"
    t.string "datadog_site"
  end

  add_foreign_key "activities", "projects"
  add_foreign_key "incidents", "projects"
end
