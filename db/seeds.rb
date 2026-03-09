# frozen_string_literal: true

# BankCORE P1 Seed Data
# Run with: bin/rails db:seed

# 1. Branch
branch = Branch.find_or_create_by!(branch_code: "MAIN") do |b|
  b.name = "Main Office"
  b.timezone_name = "America/New_York"
  b.status = Bankcore::Enums::STATUS_ACTIVE
  b.opened_on = Date.current
end

# 2. GL Accounts (per gl_account_seed_plan.md)
gl_accounts_data = [
  # Assets
  { gl_number: "1100", name: "Cash and Due from Banks", category: "asset", normal_balance: "debit", allow_direct_posting: true },
  { gl_number: "1120", name: "Due from Federal Reserve / Settlement Bank", category: "asset", normal_balance: "debit", allow_direct_posting: true },
  { gl_number: "1180", name: "Suspense / Adjustment Receivable", category: "asset", normal_balance: "debit", allow_direct_posting: true },
  # Liabilities (2100 is parent/grouping)
  { gl_number: "2100", name: "Deposits", category: "liability", normal_balance: "credit", allow_direct_posting: false },
  { gl_number: "2110", name: "Noninterest-Bearing Demand Deposits (DDA)", category: "liability", normal_balance: "credit", allow_direct_posting: true },
  { gl_number: "2120", name: "Interest-Bearing Demand Deposits (NOW)", category: "liability", normal_balance: "credit", allow_direct_posting: true },
  { gl_number: "2130", name: "Savings / Money Market Accounts", category: "liability", normal_balance: "credit", allow_direct_posting: true },
  { gl_number: "2170", name: "ACH Settlement Clearing", category: "liability", normal_balance: "credit", allow_direct_posting: true },
  { gl_number: "2190", name: "Suspense / Unidentified Deposits", category: "liability", normal_balance: "credit", allow_direct_posting: true },
  { gl_number: "2510", name: "Accrued Interest Payable – Deposits", category: "liability", normal_balance: "credit", allow_direct_posting: true },
  # Income (4500 is parent/grouping)
  { gl_number: "4500", name: "Non-Interest Income", category: "income", normal_balance: "credit", allow_direct_posting: false },
  { gl_number: "4510", name: "Deposit Service Charges", category: "income", normal_balance: "credit", allow_direct_posting: true },
  { gl_number: "4540", name: "NSF / Overdraft Fees", category: "income", normal_balance: "credit", allow_direct_posting: true },
  { gl_number: "4560", name: "Miscellaneous Income", category: "income", normal_balance: "credit", allow_direct_posting: true },
  # Expense (5100 is parent/grouping)
  { gl_number: "5100", name: "Interest Expense – Deposits", category: "expense", normal_balance: "debit", allow_direct_posting: false },
  { gl_number: "5120", name: "Interest Expense – NOW Accounts", category: "expense", normal_balance: "debit", allow_direct_posting: true },
  { gl_number: "5130", name: "Interest Expense – Savings / MMDA", category: "expense", normal_balance: "debit", allow_direct_posting: true },
  { gl_number: "5190", name: "Adjustment / Correction Expense", category: "expense", normal_balance: "debit", allow_direct_posting: true },
  # Equity
  { gl_number: "3200", name: "Retained Earnings", category: "equity", normal_balance: "credit", allow_direct_posting: true },
  { gl_number: "3300", name: "Current-Year Profit / Loss", category: "equity", normal_balance: "credit", allow_direct_posting: true }
]

gl_accounts_data.each do |attrs|
  allow_direct = attrs.delete(:allow_direct_posting)
  GlAccount.find_or_create_by!(gl_number: attrs[:gl_number]) do |g|
    g.name = attrs[:name]
    g.category = attrs[:category]
    g.normal_balance = attrs[:normal_balance]
    g.status = Bankcore::Enums::STATUS_ACTIVE
    g.allow_direct_posting = allow_direct if g.respond_to?(:allow_direct_posting=)
  end
end

# 3. Account Products
account_products_data = [
  {
    product_code: "dda",
    name: "Noninterest-Bearing DDA",
    product_family: "deposit",
    currency_code: "USD",
    statement_cycle: "monthly",
    allow_overdraft: true,
    liability_gl_number: "2110"
  },
  {
    product_code: "now",
    name: "Interest-Bearing Demand",
    product_family: "deposit",
    currency_code: "USD",
    statement_cycle: "monthly",
    allow_overdraft: true,
    interest_expense_gl_number: "5120",
    liability_gl_number: "2120"
  },
  {
    product_code: "savings",
    name: "Savings",
    product_family: "deposit",
    currency_code: "USD",
    statement_cycle: "monthly",
    allow_overdraft: false,
    interest_expense_gl_number: "5130",
    liability_gl_number: "2130"
  },
  {
    product_code: "cd",
    name: "Time Deposit",
    product_family: "deposit",
    currency_code: "USD",
    statement_cycle: "monthly",
    allow_overdraft: false,
    interest_expense_gl_number: "5130",
    liability_gl_number: "2130"
  }
]

account_products_data.each do |attrs|
  liability_gl = GlAccount.find_by!(gl_number: attrs.delete(:liability_gl_number))
  interest_expense_gl_number = attrs.delete(:interest_expense_gl_number)
  interest_expense_gl = GlAccount.find_by(gl_number: interest_expense_gl_number) if interest_expense_gl_number.present?
  product = AccountProduct.find_or_initialize_by(product_code: attrs[:product_code])
  product.assign_attributes(
    name: attrs[:name],
    product_family: attrs[:product_family],
    currency_code: attrs[:currency_code],
    statement_cycle: attrs[:statement_cycle],
    allow_overdraft: attrs[:allow_overdraft],
    status: Bankcore::Enums::STATUS_ACTIVE,
    liability_gl_account: liability_gl,
    interest_expense_gl_account: interest_expense_gl
  )
  product.save!
end

# 4. Business Date
today = Date.current
BusinessDate.find_or_create_by!(business_date: today) do |bd|
  bd.status = Bankcore::Enums::BUSINESS_DATE_OPEN
  bd.opened_at = Time.current
end

# 5. Sample Party and Account (for manual transaction entry)
party = Party.find_or_create_by!(party_number: "P001") do |p|
  p.party_type = Bankcore::Enums::PARTY_TYPE_PERSON
  p.display_name = "Sample Customer"
  p.status = Bankcore::Enums::STATUS_ACTIVE
  p.primary_branch_id = branch.id
  p.opened_on = Date.current
end

account = Account.find_or_create_by!(account_number: "1001") do |a|
  a.account_product_id = AccountProduct.find_by!(product_code: "dda").id
  a.branch_id = branch.id
  a.account_type = "dda"
  a.currency_code = "USD"
  a.status = Bankcore::Enums::STATUS_ACTIVE
  a.opened_on = Date.current
end

AccountOwner.find_or_create_by!(account_id: account.id, party_id: party.id) do |ao|
  ao.role_type = "primary"
  ao.is_primary = true
  ao.effective_on = Date.current
end

product = account.account_product
deposit_account = DepositAccount.find_or_initialize_by(account_id: account.id)
deposit_account.assign_attributes(
  deposit_type: product.default_deposit_type,
  interest_bearing: product.default_interest_bearing?,
  overdraft_policy: product.default_overdraft_policy
)
deposit_account.save!

# 6. Transaction Codes
transaction_codes_data = [
  { code: "ADJ_CREDIT", description: "Manual account credit", reversal_code: "ADJ_DEBIT" },
  { code: "ADJ_DEBIT", description: "Manual account debit", reversal_code: "ADJ_CREDIT" },
  { code: "XFER_INTERNAL", description: "Internal account transfer", reversal_code: "XFER_INTERNAL" },
  { code: "FEE_POST", description: "Fee assessment", reversal_code: "FEE_REVERSAL" },
  { code: "FEE_REVERSAL", description: "Fee reversal", reversal_code: nil },
  { code: "INT_ACCRUAL", description: "Interest accrual", reversal_code: "INT_ACCRUAL_REVERSAL" },
  { code: "INT_ACCRUAL_REVERSAL", description: "Interest accrual reversal", reversal_code: nil },
  { code: "INT_POST", description: "Interest posting", reversal_code: "INT_POST_REVERSAL" },
  { code: "INT_POST_REVERSAL", description: "Interest posting reversal", reversal_code: nil },
  { code: "ACH_CREDIT", description: "Incoming ACH", reversal_code: "ACH_DEBIT" },
  { code: "ACH_DEBIT", description: "Outgoing ACH", reversal_code: "ACH_CREDIT" }
]

transaction_codes_data.each do |attrs|
  TransactionCode.find_or_create_by!(code: attrs[:code]) do |tc|
    tc.description = attrs[:description]
    tc.reversal_code = attrs[:reversal_code]
    tc.active = true
  end
end

# 6. Posting Templates (Phase 2 + Phase 4)
if defined?(PostingTemplate)
  gl_5190 = GlAccount.find_by!(gl_number: "5190")
  gl_1180 = GlAccount.find_by!(gl_number: "1180")
  gl_4510 = GlAccount.find_by!(gl_number: "4510")
  gl_5130 = GlAccount.find_by!(gl_number: "5130")
  gl_2510 = GlAccount.find_by!(gl_number: "2510")
  gl_1120 = GlAccount.find_by!(gl_number: "1120")
  gl_2170 = GlAccount.find_by!(gl_number: "2170")

  # ADJ_CREDIT: Debit 5190, Credit customer_account
  adj_credit_code = TransactionCode.find_by!(code: "ADJ_CREDIT")
  adj_credit_tpl = PostingTemplate.find_or_create_by!(transaction_code_id: adj_credit_code.id) do |t|
    t.name = "Manual Account Credit"
    t.description = "Debit 5190 Adjustment Expense, Credit customer account"
    t.active = true
  end
  PostingTemplateLeg.find_or_create_by!(posting_template_id: adj_credit_tpl.id, position: 0) do |l|
    l.leg_type = Bankcore::Enums::LEG_TYPE_DEBIT
    l.account_source = Bankcore::Enums::ACCOUNT_SOURCE_FIXED_GL
    l.gl_account_id = gl_5190.id
    l.description = "Debit adjustment expense"
  end
  PostingTemplateLeg.find_or_create_by!(posting_template_id: adj_credit_tpl.id, position: 1) do |l|
    l.leg_type = Bankcore::Enums::LEG_TYPE_CREDIT
    l.account_source = Bankcore::Enums::ACCOUNT_SOURCE_CUSTOMER
    l.description = "Credit customer account"
  end

  # ADJ_DEBIT: Debit customer_account, Credit 1180
  adj_debit_code = TransactionCode.find_by!(code: "ADJ_DEBIT")
  adj_debit_tpl = PostingTemplate.find_or_create_by!(transaction_code_id: adj_debit_code.id) do |t|
    t.name = "Manual Account Debit"
    t.description = "Debit customer account, Credit 1180 Suspense"
    t.active = true
  end
  PostingTemplateLeg.find_or_create_by!(posting_template_id: adj_debit_tpl.id, position: 0) do |l|
    l.leg_type = Bankcore::Enums::LEG_TYPE_DEBIT
    l.account_source = Bankcore::Enums::ACCOUNT_SOURCE_CUSTOMER
    l.description = "Debit customer account"
  end
  PostingTemplateLeg.find_or_create_by!(posting_template_id: adj_debit_tpl.id, position: 1) do |l|
    l.leg_type = Bankcore::Enums::LEG_TYPE_CREDIT
    l.account_source = Bankcore::Enums::ACCOUNT_SOURCE_FIXED_GL
    l.gl_account_id = gl_1180.id
    l.description = "Credit suspense receivable"
  end

  # XFER_INTERNAL: Debit source_account, Credit destination_account
  xfer_code = TransactionCode.find_by!(code: "XFER_INTERNAL")
  xfer_tpl = PostingTemplate.find_or_create_by!(transaction_code_id: xfer_code.id) do |t|
    t.name = "Internal Transfer"
    t.description = "Debit source, Credit destination"
    t.active = true
  end
  PostingTemplateLeg.find_or_create_by!(posting_template_id: xfer_tpl.id, position: 0) do |l|
    l.leg_type = Bankcore::Enums::LEG_TYPE_DEBIT
    l.account_source = Bankcore::Enums::ACCOUNT_SOURCE_SOURCE
    l.description = "Debit source account"
  end
  PostingTemplateLeg.find_or_create_by!(posting_template_id: xfer_tpl.id, position: 1) do |l|
    l.leg_type = Bankcore::Enums::LEG_TYPE_CREDIT
    l.account_source = Bankcore::Enums::ACCOUNT_SOURCE_DESTINATION
    l.description = "Credit destination account"
  end

  # FEE_POST: Debit customer_account, Credit 4510
  fee_code = TransactionCode.find_by!(code: "FEE_POST")
  fee_tpl = PostingTemplate.find_or_create_by!(transaction_code_id: fee_code.id) do |t|
    t.name = "Fee Assessment"
    t.description = "Debit account, Credit fee income"
    t.active = true
  end
  PostingTemplateLeg.find_or_create_by!(posting_template_id: fee_tpl.id, position: 0) do |l|
    l.leg_type = Bankcore::Enums::LEG_TYPE_DEBIT
    l.account_source = Bankcore::Enums::ACCOUNT_SOURCE_CUSTOMER
    l.description = "Debit customer account"
  end
  PostingTemplateLeg.find_or_create_by!(posting_template_id: fee_tpl.id, position: 1) do |l|
    l.leg_type = Bankcore::Enums::LEG_TYPE_CREDIT
    l.account_source = Bankcore::Enums::ACCOUNT_SOURCE_FIXED_GL
    l.gl_account_id = gl_4510.id
    l.description = "Credit fee income"
  end

  # INT_ACCRUAL: Debit 5130 Interest Expense, Credit 2510 Interest Payable (GL-only)
  int_acc_code = TransactionCode.find_by!(code: "INT_ACCRUAL")
  int_acc_tpl = PostingTemplate.find_or_create_by!(transaction_code_id: int_acc_code.id) do |t|
    t.name = "Interest Accrual"
    t.description = "GL-only: Debit interest expense, Credit interest payable"
    t.active = true
  end
  int_acc_debit = PostingTemplateLeg.find_or_initialize_by(posting_template_id: int_acc_tpl.id, position: 0)
  int_acc_debit.assign_attributes(
    leg_type: Bankcore::Enums::LEG_TYPE_DEBIT,
    account_source: Bankcore::Enums::ACCOUNT_SOURCE_FIXED_GL,
    gl_account_id: nil,
    description: "Debit product interest expense"
  )
  int_acc_debit.save!
  int_acc_credit = PostingTemplateLeg.find_or_initialize_by(posting_template_id: int_acc_tpl.id, position: 1)
  int_acc_credit.assign_attributes(
    leg_type: Bankcore::Enums::LEG_TYPE_CREDIT,
    account_source: Bankcore::Enums::ACCOUNT_SOURCE_FIXED_GL,
    gl_account_id: gl_2510.id,
    description: "Credit interest payable"
  )
  int_acc_credit.save!

  # INT_POST: Debit 2510 Interest Payable, Credit customer_account
  int_post_code = TransactionCode.find_by!(code: "INT_POST")
  int_post_tpl = PostingTemplate.find_or_create_by!(transaction_code_id: int_post_code.id) do |t|
    t.name = "Interest Posting"
    t.description = "Debit interest payable, Credit customer account"
    t.active = true
  end
  PostingTemplateLeg.find_or_create_by!(posting_template_id: int_post_tpl.id, position: 0) do |l|
    l.leg_type = Bankcore::Enums::LEG_TYPE_DEBIT
    l.account_source = Bankcore::Enums::ACCOUNT_SOURCE_FIXED_GL
    l.gl_account_id = gl_2510.id
    l.description = "Debit interest payable"
  end
  PostingTemplateLeg.find_or_create_by!(posting_template_id: int_post_tpl.id, position: 1) do |l|
    l.leg_type = Bankcore::Enums::LEG_TYPE_CREDIT
    l.account_source = Bankcore::Enums::ACCOUNT_SOURCE_CUSTOMER
    l.description = "Credit customer account"
  end

  # ACH_CREDIT: Debit 1120 Settlement Bank, Credit customer_account
  ach_credit_code = TransactionCode.find_by!(code: "ACH_CREDIT")
  ach_credit_tpl = PostingTemplate.find_or_create_by!(transaction_code_id: ach_credit_code.id) do |t|
    t.name = "ACH Credit"
    t.description = "Incoming ACH: Debit settlement, Credit account"
    t.active = true
  end
  PostingTemplateLeg.find_or_create_by!(posting_template_id: ach_credit_tpl.id, position: 0) do |l|
    l.leg_type = Bankcore::Enums::LEG_TYPE_DEBIT
    l.account_source = Bankcore::Enums::ACCOUNT_SOURCE_FIXED_GL
    l.gl_account_id = gl_1120.id
    l.description = "Debit due from settlement"
  end
  PostingTemplateLeg.find_or_create_by!(posting_template_id: ach_credit_tpl.id, position: 1) do |l|
    l.leg_type = Bankcore::Enums::LEG_TYPE_CREDIT
    l.account_source = Bankcore::Enums::ACCOUNT_SOURCE_CUSTOMER
    l.description = "Credit customer account"
  end

  # ACH_DEBIT: Debit customer_account, Credit 2170 ACH Clearing
  ach_debit_code = TransactionCode.find_by!(code: "ACH_DEBIT")
  ach_debit_tpl = PostingTemplate.find_or_create_by!(transaction_code_id: ach_debit_code.id) do |t|
    t.name = "ACH Debit"
    t.description = "Outgoing ACH: Debit account, Credit clearing"
    t.active = true
  end
  PostingTemplateLeg.find_or_create_by!(posting_template_id: ach_debit_tpl.id, position: 0) do |l|
    l.leg_type = Bankcore::Enums::LEG_TYPE_DEBIT
    l.account_source = Bankcore::Enums::ACCOUNT_SOURCE_CUSTOMER
    l.description = "Debit customer account"
  end
  PostingTemplateLeg.find_or_create_by!(posting_template_id: ach_debit_tpl.id, position: 1) do |l|
    l.leg_type = Bankcore::Enums::LEG_TYPE_CREDIT
    l.account_source = Bankcore::Enums::ACCOUNT_SOURCE_FIXED_GL
    l.gl_account_id = gl_2170.id
    l.description = "Credit ACH clearing"
  end

  # FEE_REVERSAL: Credit customer_account, Debit 4510 (inverse of FEE_POST)
  fee_rev_code = TransactionCode.find_by!(code: "FEE_REVERSAL")
  fee_rev_tpl = PostingTemplate.find_or_create_by!(transaction_code_id: fee_rev_code.id) do |t|
    t.name = "Fee Reversal"
    t.description = "Credit account, Debit fee income"
    t.active = true
  end
  PostingTemplateLeg.find_or_create_by!(posting_template_id: fee_rev_tpl.id, position: 0) do |l|
    l.leg_type = Bankcore::Enums::LEG_TYPE_CREDIT
    l.account_source = Bankcore::Enums::ACCOUNT_SOURCE_CUSTOMER
    l.description = "Credit customer account"
  end
  PostingTemplateLeg.find_or_create_by!(posting_template_id: fee_rev_tpl.id, position: 1) do |l|
    l.leg_type = Bankcore::Enums::LEG_TYPE_DEBIT
    l.account_source = Bankcore::Enums::ACCOUNT_SOURCE_FIXED_GL
    l.gl_account_id = gl_4510.id
    l.description = "Debit fee income"
  end

  # INT_ACCRUAL_REVERSAL: Credit 5130, Debit 2510 (inverse of INT_ACCRUAL, GL-only)
  int_acc_rev_code = TransactionCode.find_by!(code: "INT_ACCRUAL_REVERSAL")
  int_acc_rev_tpl = PostingTemplate.find_or_create_by!(transaction_code_id: int_acc_rev_code.id) do |t|
    t.name = "Interest Accrual Reversal"
    t.description = "GL-only: Credit interest expense, Debit interest payable"
    t.active = true
  end
  PostingTemplateLeg.find_or_create_by!(posting_template_id: int_acc_rev_tpl.id, position: 0) do |l|
    l.leg_type = Bankcore::Enums::LEG_TYPE_CREDIT
    l.account_source = Bankcore::Enums::ACCOUNT_SOURCE_FIXED_GL
    l.gl_account_id = gl_5130.id
    l.description = "Credit interest expense"
  end
  PostingTemplateLeg.find_or_create_by!(posting_template_id: int_acc_rev_tpl.id, position: 1) do |l|
    l.leg_type = Bankcore::Enums::LEG_TYPE_DEBIT
    l.account_source = Bankcore::Enums::ACCOUNT_SOURCE_FIXED_GL
    l.gl_account_id = gl_2510.id
    l.description = "Debit interest payable"
  end

  # INT_POST_REVERSAL: Credit 2510, Debit customer_account (inverse of INT_POST)
  int_post_rev_code = TransactionCode.find_by!(code: "INT_POST_REVERSAL")
  int_post_rev_tpl = PostingTemplate.find_or_create_by!(transaction_code_id: int_post_rev_code.id) do |t|
    t.name = "Interest Posting Reversal"
    t.description = "Credit interest payable, Debit customer account"
    t.active = true
  end
  PostingTemplateLeg.find_or_create_by!(posting_template_id: int_post_rev_tpl.id, position: 0) do |l|
    l.leg_type = Bankcore::Enums::LEG_TYPE_CREDIT
    l.account_source = Bankcore::Enums::ACCOUNT_SOURCE_FIXED_GL
    l.gl_account_id = gl_2510.id
    l.description = "Credit interest payable"
  end
  PostingTemplateLeg.find_or_create_by!(posting_template_id: int_post_rev_tpl.id, position: 1) do |l|
    l.leg_type = Bankcore::Enums::LEG_TYPE_DEBIT
    l.account_source = Bankcore::Enums::ACCOUNT_SOURCE_CUSTOMER
    l.description = "Debit customer account"
  end
end

# 7. Sample Party and Account (for manual transaction entry UI)
party = Party.find_or_create_by!(party_number: "P001") do |p|
  p.party_type = Bankcore::Enums::PARTY_TYPE_PERSON
  p.display_name = "Sample Customer"
  p.status = Bankcore::Enums::STATUS_ACTIVE
  p.primary_branch_id = branch.id
  p.opened_on = Date.current
end

account = Account.find_or_create_by!(account_number: "1001") do |a|
  a.account_product_id = AccountProduct.find_by!(product_code: "dda").id
  a.branch_id = branch.id
  a.account_type = "dda"
  a.currency_code = "USD"
  a.status = Bankcore::Enums::STATUS_ACTIVE
  a.opened_on = Date.current
end

AccountOwner.find_or_create_by!(account_id: account.id, party_id: party.id) do |ao|
  ao.role_type = "primary"
  ao.is_primary = true
  ao.effective_on = Date.current
end

DepositAccount.find_or_create_by!(account_id: account.id) do |da|
  da.deposit_type = "dda"
  da.interest_bearing = false
end

# Second account for internal transfers
account2 = Account.find_or_create_by!(account_number: "1002") do |a|
  a.account_product_id = AccountProduct.find_by!(product_code: "savings").id
  a.branch_id = branch.id
  a.account_type = "savings"
  a.currency_code = "USD"
  a.status = Bankcore::Enums::STATUS_ACTIVE
  a.opened_on = Date.current
end

AccountOwner.find_or_create_by!(account_id: account2.id, party_id: party.id) do |ao|
  ao.role_type = "primary"
  ao.is_primary = false
  ao.effective_on = Date.current
end

product = account2.account_product
deposit_account = DepositAccount.find_or_initialize_by(account_id: account2.id)
deposit_account.assign_attributes(
  deposit_type: product.default_deposit_type,
  interest_bearing: product.default_interest_bearing?,
  overdraft_policy: product.default_overdraft_policy
)
deposit_account.save!

# 8. Fee Types (Phase 5)
if defined?(FeeType)
  gl_4510 = GlAccount.find_by!(gl_number: "4510")
  FeeType.find_or_create_by!(code: "MAINTENANCE") do |ft|
    ft.name = "Monthly Maintenance Fee"
    ft.default_amount_cents = 1500 # $15.00
    ft.gl_account_id = gl_4510.id
    ft.status = Bankcore::Enums::STATUS_ACTIVE
  end
  FeeType.find_or_create_by!(code: "SERVICE_CHARGE") do |ft|
    ft.name = "Service Charge"
    ft.default_amount_cents = 500 # $5.00
    ft.gl_account_id = gl_4510.id
    ft.status = Bankcore::Enums::STATUS_ACTIVE
  end
end

# 9. Roles and permissions
if defined?(Role)
  back_office = Role.find_or_create_by!(code: "back_office") do |r|
    r.name = "Back Office"
    r.description = "Can post and reverse manual transactions"
  end
  %w[post_transactions reverse_transactions].each do |code|
    RolePermission.find_or_create_by!(role: back_office, permission_code: code)
  end

  supervisor = Role.find_or_create_by!(code: "supervisor") do |r|
    r.name = "Supervisor"
    r.description = "Can approve override requests"
  end
  RolePermission.find_or_create_by!(role: supervisor, permission_code: "approve_overrides")
end

# 10. Seed user for authentication (username: ops, password: password)
if defined?(User) && User.column_names.include?("password_digest")
  ops_user = User.find_or_create_by!(username: "ops") do |u|
    u.display_name = "Operations User"
    u.status = Bankcore::Enums::STATUS_ACTIVE
    u.primary_branch_id = branch.id
    u.password = "password"
    u.password_confirmation = "password"
  end
  if defined?(UserRole) && defined?(Role)
    [ "back_office", "supervisor" ].each do |role_code|
      role = Role.find_by(code: role_code)
      UserRole.find_or_create_by!(user: ops_user, role: role) if role
    end
  end
end

puts "BankCORE seeds complete: 1 branch, #{GlAccount.count} GL accounts, #{AccountProduct.count} account products, 1 business date, #{TransactionCode.count} transaction codes, #{PostingTemplate.count} posting templates, #{Party.count} parties, #{Account.count} accounts#{', ' + FeeType.count.to_s + ' fee types' if defined?(FeeType)}#{User.column_names.include?('password_digest') ? ", 1 ops user (username: ops, password: password)" : ''}."
