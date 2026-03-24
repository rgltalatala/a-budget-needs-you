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

ActiveRecord::Schema[8.1].define(version: 2026_03_16_120000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "account_groups", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "sort_order", default: 0
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["user_id", "name"], name: "index_account_groups_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_account_groups_on_user_id"
  end

  create_table "accounts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "account_group_id", limit: 36
    t.string "account_type"
    t.decimal "balance", default: "0.0", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["account_group_id"], name: "index_accounts_on_account_group_id"
    t.index ["user_id", "name"], name: "index_accounts_on_user_id_and_name"
    t.index ["user_id"], name: "index_accounts_on_user_id"
  end

  create_table "budget_months", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.decimal "available", default: "0.0"
    t.uuid "budget_id", null: false
    t.datetime "created_at", null: false
    t.date "month", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["budget_id", "month"], name: "index_budget_months_on_budget_id_and_month", unique: true
    t.index ["budget_id"], name: "index_budget_months_on_budget_id"
    t.index ["month"], name: "index_budget_months_on_month"
    t.index ["user_id"], name: "index_budget_months_on_user_id"
  end

  create_table "budgets", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["user_id"], name: "index_budgets_on_user_id"
  end

  create_table "categories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "category_group_id"
    t.datetime "created_at", null: false
    t.boolean "is_default", default: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.index ["category_group_id"], name: "index_categories_on_category_group_id"
    t.index ["user_id", "category_group_id", "name"], name: "index_categories_on_user_group_name_unique", unique: true, where: "((category_group_id IS NOT NULL) AND (user_id IS NOT NULL))"
    t.index ["user_id", "name"], name: "index_categories_on_user_and_name_no_group_unique", unique: true, where: "((category_group_id IS NULL) AND (user_id IS NOT NULL))"
    t.index ["user_id", "name"], name: "index_categories_on_user_id_and_name"
    t.index ["user_id"], name: "index_categories_on_user_id"
  end

  create_table "category_groups", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "budget_month_id"
    t.datetime "created_at", null: false
    t.boolean "is_default", default: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.index ["budget_month_id", "name"], name: "index_category_groups_on_budget_month_id_and_name"
    t.index ["budget_month_id"], name: "index_category_groups_on_budget_month_id"
    t.index ["user_id"], name: "index_category_groups_on_user_id"
  end

  create_table "category_months", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.decimal "allotted", default: "0.0"
    t.decimal "balance", default: "0.0"
    t.uuid "category_group_id"
    t.uuid "category_id", null: false
    t.datetime "created_at", null: false
    t.date "month"
    t.decimal "spent", default: "0.0"
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["category_group_id"], name: "index_category_months_on_category_group_id"
    t.index ["category_id", "month"], name: "index_category_months_on_category_id_and_month"
    t.index ["category_id"], name: "index_category_months_on_category_id"
    t.index ["month"], name: "index_category_months_on_month"
    t.index ["user_id"], name: "index_category_months_on_user_id"
  end

  create_table "goals", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "category_id", null: false
    t.datetime "created_at", null: false
    t.string "goal_type", null: false
    t.decimal "target_amount"
    t.date "target_date"
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["category_id"], name: "index_goals_on_category_id", unique: true
    t.index ["user_id"], name: "index_goals_on_user_id"
  end

  create_table "summaries", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.decimal "available", default: "0.0"
    t.uuid "budget_month_id", null: false
    t.decimal "carryover", default: "0.0"
    t.datetime "created_at", null: false
    t.decimal "income", default: "0.0"
    t.text "notes"
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["budget_month_id"], name: "index_summaries_on_budget_month_id", unique: true
    t.index ["user_id"], name: "index_summaries_on_user_id"
  end

  create_table "transactions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.decimal "amount", null: false
    t.uuid "category_id", null: false
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.text "payee"
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["account_id"], name: "index_transactions_on_account_id"
    t.index ["category_id"], name: "index_transactions_on_category_id"
    t.index ["date"], name: "index_transactions_on_date"
    t.index ["user_id", "date"], name: "index_transactions_on_user_id_and_date"
    t.index ["user_id"], name: "index_transactions_on_user_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name"
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end
end
