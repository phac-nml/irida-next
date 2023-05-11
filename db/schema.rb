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

ActiveRecord::Schema[7.0].define(version: 2023_04_26_174630) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "members", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "namespace_id"
    t.bigint "created_by_id"
    t.integer "access_level"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_members_on_created_by_id"
    t.index ["namespace_id"], name: "index_members_on_namespace_id"
    t.index ["user_id", "namespace_id"], name: "index_members_on_user_id_and_namespace_id", unique: true
    t.index ["user_id"], name: "index_members_on_user_id"
  end

  create_table "namespaces", force: :cascade do |t|
    t.string "name"
    t.string "path"
    t.bigint "owner_id"
    t.string "type"
    t.string "description"
    t.bigint "parent_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_id"], name: "index_namespaces_on_owner_id"
    t.index ["parent_id"], name: "index_namespaces_on_parent_id"
  end

  create_table "personal_access_tokens", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "scopes"
    t.string "name"
    t.boolean "revoked", default: false, null: false
    t.date "expires_at"
    t.string "token_digest"
    t.datetime "last_used_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token_digest"], name: "index_personal_access_tokens_on_token_digest", unique: true
    t.index ["user_id"], name: "index_personal_access_tokens_on_user_id"
  end

  create_table "projects", force: :cascade do |t|
    t.bigint "creator_id"
    t.bigint "namespace_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_projects_on_creator_id"
    t.index ["namespace_id"], name: "index_projects_on_namespace_id"
  end

  create_table "routes", force: :cascade do |t|
    t.string "path"
    t.string "name"
    t.string "source_type"
    t.bigint "source_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_routes_on_name", unique: true
    t.index ["path"], name: "index_routes_on_path", unique: true
    t.index ["source_type", "source_id"], name: "index_routes_on_source"
  end

  create_table "samples", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.bigint "project_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name", "project_id"], name: "index_samples_on_name_and_project_id", unique: true
    t.index ["project_id"], name: "index_samples_on_project_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "provider"
    t.string "uid"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "members", "namespaces"
  add_foreign_key "members", "users"
  add_foreign_key "namespaces", "namespaces", column: "parent_id"
  add_foreign_key "personal_access_tokens", "users"
  add_foreign_key "projects", "namespaces"
  add_foreign_key "samples", "projects"
end
