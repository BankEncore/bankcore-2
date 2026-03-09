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

ActiveRecord::Schema[8.1].define(version: 2026_03_09_050000) do
  create_table "account_balances", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "as_of_at"
    t.integer "available_balance_cents"
    t.datetime "created_at", null: false
    t.integer "posted_balance_cents"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_account_balances_on_account_id", unique: true
  end

  create_table "account_holds", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.integer "amount_cents", null: false
    t.datetime "created_at", null: false
    t.date "effective_on", null: false
    t.string "hold_type", null: false
    t.string "reason_code"
    t.date "release_on"
    t.datetime "released_at"
    t.string "status", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "status"], name: "index_account_holds_on_account_id_and_status"
    t.index ["account_id"], name: "index_account_holds_on_account_id"
  end

  create_table "account_owners", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.date "effective_on"
    t.date "ends_on"
    t.boolean "is_primary"
    t.bigint "party_id", null: false
    t.string "role_type"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_account_owners_on_account_id"
    t.index ["party_id"], name: "index_account_owners_on_party_id"
  end

  create_table "account_products", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.boolean "allow_overdraft", default: false, null: false
    t.bigint "asset_gl_account_id"
    t.datetime "created_at", null: false
    t.string "currency_code", default: "USD", null: false
    t.bigint "interest_expense_gl_account_id"
    t.bigint "liability_gl_account_id"
    t.string "name", null: false
    t.string "product_code", null: false
    t.string "product_family", null: false
    t.string "statement_cycle", default: "monthly", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["asset_gl_account_id"], name: "index_account_products_on_asset_gl_account_id"
    t.index ["interest_expense_gl_account_id"], name: "index_account_products_on_interest_expense_gl_account_id"
    t.index ["liability_gl_account_id"], name: "index_account_products_on_liability_gl_account_id"
    t.index ["product_code"], name: "index_account_products_on_product_code", unique: true
  end

  create_table "account_transactions", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.integer "amount_cents"
    t.date "business_date"
    t.bigint "contra_account_id"
    t.datetime "created_at", null: false
    t.string "description"
    t.string "direction"
    t.datetime "posted_at"
    t.bigint "posting_batch_id", null: false
    t.integer "running_balance_cents"
    t.bigint "transaction_id"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_account_transactions_on_account_id"
    t.index ["contra_account_id"], name: "index_account_transactions_on_contra_account_id"
    t.index ["posting_batch_id"], name: "index_account_transactions_on_posting_batch_id"
    t.index ["transaction_id"], name: "index_account_transactions_on_transaction_id"
  end

  create_table "accounts", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "account_number", null: false
    t.bigint "account_product_id"
    t.string "account_type", null: false
    t.bigint "branch_id", null: false
    t.date "closed_on"
    t.datetime "created_at", null: false
    t.string "currency_code", default: "USD", null: false
    t.date "opened_on"
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["account_number"], name: "index_accounts_on_account_number", unique: true
    t.index ["account_product_id"], name: "index_accounts_on_account_product_id"
    t.index ["branch_id"], name: "index_accounts_on_branch_id"
  end

  create_table "audit_events", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "action", null: false
    t.bigint "actor_id"
    t.string "actor_type"
    t.date "business_date"
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.text "metadata_json"
    t.datetime "occurred_at", null: false
    t.string "status"
    t.bigint "target_id"
    t.string "target_type"
    t.datetime "updated_at", null: false
    t.index ["event_type", "occurred_at"], name: "index_audit_events_on_event_type_and_occurred_at"
    t.index ["target_type", "target_id"], name: "index_audit_events_on_target_type_and_target_id"
  end

  create_table "branches", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "branch_code", null: false
    t.date "closed_on"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.date "opened_on"
    t.string "status", default: "active", null: false
    t.string "timezone_name", default: "America/New_York"
    t.datetime "updated_at", null: false
    t.index ["branch_code"], name: "index_branches_on_branch_code", unique: true
  end

  create_table "business_dates", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.date "business_date", null: false
    t.datetime "closed_at"
    t.datetime "created_at", null: false
    t.datetime "opened_at"
    t.string "status", default: "open", null: false
    t.datetime "updated_at", null: false
    t.index ["business_date"], name: "index_business_dates_on_business_date", unique: true
  end

  create_table "deposit_accounts", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.string "deposit_type"
    t.boolean "interest_bearing"
    t.integer "interest_rate_basis_points"
    t.integer "minimum_balance_cents"
    t.string "overdraft_policy"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_deposit_accounts_on_account_id", unique: true
  end

  create_table "fee_assessments", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.integer "amount_cents", null: false
    t.date "assessed_on", null: false
    t.datetime "created_at", null: false
    t.bigint "fee_rule_id"
    t.bigint "fee_type_id", null: false
    t.bigint "posting_batch_id"
    t.string "status", default: "posted", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "assessed_on"], name: "index_fee_assessments_on_account_id_and_assessed_on"
    t.index ["account_id"], name: "index_fee_assessments_on_account_id"
    t.index ["fee_rule_id"], name: "index_fee_assessments_on_fee_rule_id"
    t.index ["fee_type_id"], name: "index_fee_assessments_on_fee_type_id"
    t.index ["posting_batch_id"], name: "index_fee_assessments_on_posting_batch_id"
  end

  create_table "fee_rules", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "account_product_id", null: false
    t.integer "amount_cents"
    t.text "conditions_json"
    t.datetime "created_at", null: false
    t.date "effective_on"
    t.date "ends_on"
    t.bigint "fee_type_id", null: false
    t.bigint "gl_account_id"
    t.string "method", default: "fixed_amount", null: false
    t.integer "priority", default: 100, null: false
    t.datetime "updated_at", null: false
    t.index ["account_product_id"], name: "index_fee_rules_on_account_product_id"
    t.index ["fee_type_id", "account_product_id", "priority"], name: "index_fee_rules_on_fee_type_product_priority", unique: true
    t.index ["fee_type_id"], name: "index_fee_rules_on_fee_type_id"
    t.index ["gl_account_id"], name: "index_fee_rules_on_gl_account_id"
  end

  create_table "fee_types", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.integer "default_amount_cents", default: 0, null: false
    t.bigint "gl_account_id"
    t.string "name", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_fee_types_on_code", unique: true
    t.index ["gl_account_id"], name: "index_fee_types_on_gl_account_id"
  end

  create_table "gl_accounts", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.boolean "allow_direct_posting", default: true, null: false
    t.string "category", null: false
    t.datetime "created_at", null: false
    t.string "description"
    t.string "gl_number", null: false
    t.string "name", null: false
    t.string "normal_balance", null: false
    t.bigint "parent_gl_account_id"
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["gl_number"], name: "index_gl_accounts_on_gl_number", unique: true
    t.index ["parent_gl_account_id"], name: "index_gl_accounts_on_parent_gl_account_id"
  end

  create_table "interest_accruals", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.date "accrual_date", null: false
    t.integer "amount_cents", null: false
    t.datetime "created_at", null: false
    t.bigint "posting_batch_id"
    t.string "status", default: "posted", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "accrual_date"], name: "index_interest_accruals_on_account_id_and_accrual_date"
    t.index ["account_id"], name: "index_interest_accruals_on_account_id"
    t.index ["posting_batch_id"], name: "index_interest_accruals_on_posting_batch_id"
  end

  create_table "journal_entries", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.date "business_date"
    t.datetime "created_at", null: false
    t.datetime "posted_at"
    t.bigint "posting_batch_id", null: false
    t.string "reference_number"
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["posting_batch_id"], name: "index_journal_entries_on_posting_batch_id"
  end

  create_table "journal_entry_lines", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "branch_id"
    t.datetime "created_at", null: false
    t.integer "credit_cents"
    t.string "currency_code"
    t.integer "debit_cents"
    t.bigint "gl_account_id", null: false
    t.bigint "journal_entry_id", null: false
    t.string "memo"
    t.integer "position"
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_journal_entry_lines_on_branch_id"
    t.index ["gl_account_id"], name: "index_journal_entry_lines_on_gl_account_id"
    t.index ["journal_entry_id"], name: "index_journal_entry_lines_on_journal_entry_id"
  end

  create_table "override_requests", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "approved_by_id"
    t.bigint "branch_id"
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.bigint "operational_transaction_id"
    t.text "reason_text"
    t.string "request_type", null: false
    t.bigint "requested_by_id"
    t.string "status", null: false
    t.datetime "updated_at", null: false
    t.datetime "used_at"
    t.index ["approved_by_id"], name: "index_override_requests_on_approved_by_id"
    t.index ["branch_id"], name: "index_override_requests_on_branch_id"
    t.index ["operational_transaction_id"], name: "index_override_requests_on_operational_transaction_id"
    t.index ["requested_by_id"], name: "index_override_requests_on_requested_by_id"
  end

  create_table "parties", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.date "closed_on"
    t.datetime "created_at", null: false
    t.string "display_name", null: false
    t.date "opened_on"
    t.string "party_number", null: false
    t.string "party_type", null: false
    t.bigint "primary_branch_id"
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["party_number"], name: "index_parties_on_party_number", unique: true
    t.index ["primary_branch_id"], name: "index_parties_on_primary_branch_id"
  end

  create_table "posting_batches", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.date "business_date", null: false
    t.datetime "created_at", null: false
    t.string "idempotency_fingerprint"
    t.string "idempotency_key"
    t.text "idempotency_payload_json"
    t.bigint "operational_transaction_id"
    t.datetime "posted_at"
    t.string "posting_reference"
    t.bigint "reversal_of_batch_id"
    t.string "status", default: "draft", null: false
    t.string "transaction_code", null: false
    t.datetime "updated_at", null: false
    t.index ["idempotency_key"], name: "index_posting_batches_on_idempotency_key", unique: true
    t.index ["operational_transaction_id"], name: "index_posting_batches_on_operational_transaction_id"
    t.index ["posting_reference"], name: "index_posting_batches_on_posting_reference", unique: true
    t.index ["reversal_of_batch_id"], name: "index_posting_batches_on_reversal_of_batch_id", unique: true
  end

  create_table "posting_legs", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "account_id"
    t.integer "amount_cents", null: false
    t.datetime "created_at", null: false
    t.string "currency_code", default: "USD", null: false
    t.bigint "gl_account_id"
    t.string "ledger_scope", null: false
    t.string "leg_type", null: false
    t.integer "position"
    t.bigint "posting_batch_id", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_posting_legs_on_account_id"
    t.index ["gl_account_id"], name: "index_posting_legs_on_gl_account_id"
    t.index ["posting_batch_id"], name: "index_posting_legs_on_posting_batch_id"
  end

  create_table "posting_template_legs", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "account_source"
    t.datetime "created_at", null: false
    t.string "description"
    t.bigint "gl_account_id"
    t.string "leg_type"
    t.integer "position"
    t.bigint "posting_template_id", null: false
    t.datetime "updated_at", null: false
    t.index ["gl_account_id"], name: "index_posting_template_legs_on_gl_account_id"
    t.index ["posting_template_id"], name: "index_posting_template_legs_on_posting_template_id"
  end

  create_table "posting_templates", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.boolean "active"
    t.datetime "created_at", null: false
    t.string "description"
    t.string "name"
    t.bigint "transaction_code_id", null: false
    t.datetime "updated_at", null: false
    t.index ["transaction_code_id"], name: "index_posting_templates_on_transaction_code_id"
  end

  create_table "role_permissions", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "permission_code"
    t.bigint "role_id", null: false
    t.datetime "updated_at", null: false
    t.index ["role_id"], name: "index_role_permissions_on_role_id"
  end

  create_table "roles", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "code"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "transaction_codes", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.string "description"
    t.string "reversal_code"
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_transaction_codes_on_code", unique: true
  end

  create_table "transactions", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "approved_by_id"
    t.bigint "branch_id", null: false
    t.date "business_date"
    t.string "channel"
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.string "external_reference"
    t.datetime "initiated_at"
    t.text "memo"
    t.datetime "posted_at"
    t.text "reason_text"
    t.string "reference_number"
    t.string "status"
    t.string "transaction_type"
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_transactions_on_branch_id"
    t.index ["business_date", "reference_number"], name: "index_transactions_on_business_date_and_reference_number", unique: true
  end

  create_table "user_roles", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "role_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["role_id"], name: "index_user_roles_on_role_id"
    t.index ["user_id"], name: "index_user_roles_on_user_id"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "display_name"
    t.string "email"
    t.string "password_digest"
    t.bigint "primary_branch_id"
    t.string "status"
    t.datetime "updated_at", null: false
    t.string "username"
    t.index ["primary_branch_id"], name: "index_users_on_primary_branch_id"
  end

  add_foreign_key "account_balances", "accounts"
  add_foreign_key "account_holds", "accounts"
  add_foreign_key "account_owners", "accounts"
  add_foreign_key "account_owners", "parties"
  add_foreign_key "account_products", "gl_accounts", column: "asset_gl_account_id"
  add_foreign_key "account_products", "gl_accounts", column: "interest_expense_gl_account_id"
  add_foreign_key "account_products", "gl_accounts", column: "liability_gl_account_id"
  add_foreign_key "account_transactions", "accounts"
  add_foreign_key "account_transactions", "accounts", column: "contra_account_id"
  add_foreign_key "account_transactions", "posting_batches"
  add_foreign_key "account_transactions", "transactions"
  add_foreign_key "accounts", "account_products"
  add_foreign_key "accounts", "branches"
  add_foreign_key "deposit_accounts", "accounts"
  add_foreign_key "fee_assessments", "accounts"
  add_foreign_key "fee_assessments", "fee_rules"
  add_foreign_key "fee_assessments", "fee_types"
  add_foreign_key "fee_assessments", "posting_batches"
  add_foreign_key "fee_rules", "account_products"
  add_foreign_key "fee_rules", "fee_types"
  add_foreign_key "fee_rules", "gl_accounts"
  add_foreign_key "fee_types", "gl_accounts"
  add_foreign_key "gl_accounts", "gl_accounts", column: "parent_gl_account_id"
  add_foreign_key "interest_accruals", "accounts"
  add_foreign_key "interest_accruals", "posting_batches"
  add_foreign_key "journal_entries", "posting_batches"
  add_foreign_key "journal_entry_lines", "branches"
  add_foreign_key "journal_entry_lines", "gl_accounts"
  add_foreign_key "journal_entry_lines", "journal_entries"
  add_foreign_key "override_requests", "branches"
  add_foreign_key "override_requests", "transactions", column: "operational_transaction_id"
  add_foreign_key "override_requests", "users", column: "approved_by_id"
  add_foreign_key "override_requests", "users", column: "requested_by_id"
  add_foreign_key "parties", "branches", column: "primary_branch_id"
  add_foreign_key "posting_batches", "posting_batches", column: "reversal_of_batch_id"
  add_foreign_key "posting_batches", "transactions", column: "operational_transaction_id"
  add_foreign_key "posting_legs", "accounts"
  add_foreign_key "posting_legs", "gl_accounts"
  add_foreign_key "posting_legs", "posting_batches"
  add_foreign_key "posting_template_legs", "gl_accounts"
  add_foreign_key "posting_template_legs", "posting_templates"
  add_foreign_key "posting_templates", "transaction_codes"
  add_foreign_key "role_permissions", "roles"
  add_foreign_key "transactions", "branches"
  add_foreign_key "user_roles", "roles"
  add_foreign_key "user_roles", "users"
  add_foreign_key "users", "branches", column: "primary_branch_id"
end
