# frozen_string_literal: true

class InterestAccrualRunnerService
  # Runs daily interest accrual for all eligible deposit accounts.
  # Finds interest-bearing accounts with positive balance, calculates daily interest,
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
    DepositAccount
      .joins(:account)
      .where(interest_bearing: true)
      .where("deposit_accounts.interest_rate_basis_points > 0")
      .where(accounts: { status: Bankcore::Enums::STATUS_ACTIVE })
  end

  def accrue_account(deposit_account)
    account_id = deposit_account.account_id

    if already_accrued?(account_id)
      return { status: :skipped, account_id: account_id, reason: "already_accrued" }
    end

    balance_cents = posted_balance_cents(account_id)
    if balance_cents <= 0
      return { status: :skipped, account_id: account_id, reason: "zero_balance" }
    end

    amount_cents = calculate_daily_interest(
      balance_cents,
      deposit_account.interest_rate_basis_points
    )
    if amount_cents <= 0
      return { status: :skipped, account_id: account_id, reason: "rounds_to_zero" }
    end

    InterestAccrualService.accrue!(
      account_id: account_id,
      amount_cents: amount_cents,
      accrual_date: @accrual_date,
      idempotency_key: idempotency_key(account_id)
    )

    { status: :accrued, account_id: account_id, amount_cents: amount_cents }
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

  def calculate_daily_interest(balance_cents, rate_basis_points)
    # Daily interest = balance * (rate/10000) / 365
    # Use floor to avoid over-accruing
    (balance_cents * rate_basis_points / (10_000.0 * 365)).floor
  end

  def idempotency_key(account_id)
    "int-accrual-#{account_id}-#{@accrual_date}"
  end
end
