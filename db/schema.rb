# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170519164013) do

  create_table "commands", force: :cascade do |t|
    t.integer  "environment_id", limit: 4
    t.integer  "service_id",     limit: 4
    t.string   "version",        limit: 255
    t.string   "desc",           limit: 255
    t.text     "cmd",            limit: 65535
    t.string   "output",         limit: 255
    t.string   "state",          limit: 255
    t.string   "pod_name",       limit: 255
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
  end

  add_index "commands", ["environment_id"], name: "index_commands_on_environment_id", using: :btree
  add_index "commands", ["service_id"], name: "index_commands_on_service_id", using: :btree

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   limit: 4,     default: 0, null: false
    t.integer  "attempts",   limit: 4,     default: 0, null: false
    t.text     "handler",    limit: 65535,             null: false
    t.text     "last_error", limit: 65535
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by",  limit: 255
    t.string   "queue",      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "environments", force: :cascade do |t|
    t.string   "name",         limit: 255
    t.integer  "suite_id",     limit: 4
    t.string   "k8s_master",   limit: 255
    t.string   "k8s_username", limit: 255
    t.string   "k8s_password", limit: 255
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  add_index "environments", ["suite_id"], name: "index_environments_on_suite_id", using: :btree

  create_table "services", force: :cascade do |t|
    t.string   "name",        limit: 255
    t.integer  "suite_id",    limit: 4
    t.string   "docker_repo", limit: 255
    t.string   "git_repo",    limit: 255
    t.string   "k8s_service", limit: 255
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  add_index "services", ["suite_id"], name: "index_services_on_suite_id", using: :btree

  create_table "suites", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_foreign_key "environments", "suites"
  add_foreign_key "services", "suites"
end
