# frozen_string_literal: true

class InterestAccrualRunnerService
  # Runs daily interest accrual for all eligible deposit accounts.
  # Finds interest-bearing accounts with active product rules, calculates daily interest,
  # and posts via InterestAccrualService.
  def self.run!(accrual_date: nil)
    new(accrual_date: accrual_date).run!
  end

  def initialize(accrual_date: nil)
    @accrual_date = accrual_date || BusinessDateService.current
  end

  def run!
    results = { accrued: [], skipped: [], errors: [] }

    eligible_accounts.find_each do |deposit_account|
      result = accrue_account(deposit_account)
      results[result[:status]] << result
    end

    results
  end

  private

  def eligible_accounts
    return DepositAccount.none if active_rules_by_product.empty?

    DepositAccount
      .joins(:account)
      .where(interest_bearing: true)
      .where(accounts: { account_product_id: active_rules_by_product.keys })
      .where(accounts: { status: Bankcore::Enums::STATUS_ACTIVE })
  end

  def accrue_account(deposit_account)
    account_id = deposit_account.account_id
    interest_rule = active_rules_by_product[deposit_account.account.account_product_id]
    return { status: :skipped, account_id: account_id, reason: "no_rule" } unless interest_rule

    if already_accrued?(account_id)
      return { status: :skipped, account_id: account_id, reason: "already_accrued" }
    end

    balance_cents = posted_balance_cents(account_id)
    if balance_cents <= 0
      return { status: :skipped, account_id: account_id, reason: "zero_balance" }
    end

    amount_cents = calculate_daily_interest(
      balance_cents,
      resolved_annual_rate(deposit_account, interest_rule),
      interest_rule.day_count_method
    )
    if amount_cents <= 0
      return { status: :skipped, account_id: account_id, reason: "rounds_to_zero" }
    end

    InterestAccrualService.accrue!(
      account_id: account_id,
      amount_cents: amount_cents,
      accrual_date: @accrual_date,
      idempotency_key: idempotency_key(account_id),
      interest_rule_id: interest_rule.id
    )

    { status: :accrued, account_id: account_id, amount_cents: amount_cents, interest_rule_id: interest_rule.id }
  rescue StandardError => e
    { status: :errors, account_id: account_id, error: e.message }
  end

  def already_accrued?(account_id)
    InterestAccrual.exists?(
      account_id: account_id,
      accrual_date: @accrual_date
    )
  end

  def posted_balance_cents(account_id)
    balance = AccountBalance.find_by(account_id: account_id)
    return 0 unless balance

    balance.posted_balance_cents.to_i
  end

  def calculate_daily_interest(balance_cents, annual_rate, day_count_method)
    denominator = day_count_denominator(day_count_method)
    # Daily interest = balance * annual_rate / day_count_denominator
    # Use floor to avoid over-accruing
    (balance_cents * annual_rate.to_d / denominator).floor
  end

  def idempotency_key(account_id)
    "int-accrual-#{account_id}-#{@accrual_date}"
  end

  def active_rules_by_product
    @active_rules_by_product ||= InterestRule
      .where(account_product_id: eligible_product_ids)
      .active_on(@accrual_date)
      .ordered
      .each_with_object({}) do |interest_rule, result|
        result[interest_rule.account_product_id] ||= interest_rule
      end
  end

  def eligible_product_ids
    AccountProduct.where(status: Bankcore::Enums::STATUS_ACTIVE).pluck(:id)
  end

  def resolved_annual_rate(deposit_account, interest_rule)
    override_basis_points = deposit_account.interest_rate_basis_points.to_i
    return BigDecimal(override_basis_points.to_s) / 10_000 if override_basis_points.positive?

    interest_rule.rate.to_d
  end

  def day_count_denominator(day_count_method)
    case day_count_method
    when InterestRule::DAY_COUNT_METHOD_30_360 then 360
    else 365
    end
  end
end
