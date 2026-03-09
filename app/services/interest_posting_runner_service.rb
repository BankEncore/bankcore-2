# frozen_string_literal: true

class InterestPostingRunnerService
  def self.run!(business_date: nil)
    new(business_date: business_date).run!
  end

  def initialize(business_date: nil)
    @business_date = business_date || BusinessDateService.current
  end

  def run!
    results = { posted: [], skipped: [], errors: [] }

    eligible_accounts.find_each do |account|
      result = post_account_interest(account)
      results[result[:status]] << result
    end

    results
  end

  private

  def eligible_accounts
    return Account.none if active_rules_by_product.empty?

    Account
      .includes(:account_product, :deposit_account)
      .joins(:deposit_account)
      .where(status: Bankcore::Enums::STATUS_ACTIVE, account_product_id: active_rules_by_product.keys)
      .where(deposit_accounts: { interest_bearing: true })
  end

  def post_account_interest(account)
    interest_rule = active_rules_by_product[account.account_product_id]
    return { status: :skipped, account_id: account.id, reason: "no_rule" } unless interest_rule
    return { status: :skipped, account_id: account.id, reason: "cadence_not_due" } unless cadence_due?(interest_rule)

    accruals = unposted_accruals_for(account)
    return { status: :skipped, account_id: account.id, reason: "no_unposted_accruals" } if accruals.empty?

    amount_cents = accruals.sum(&:amount_cents)
    return { status: :skipped, account_id: account.id, reason: "zero_amount" } if amount_cents <= 0

    batch = ActiveRecord::Base.transaction do
      posting_batch = InterestPostingService.post!(
        account_id: account.id,
        amount_cents: amount_cents,
        business_date: @business_date,
        idempotency_key: idempotency_key(account.id),
        idempotency_context: {
          service: "interest_posting_runner",
          cutoff_date: @business_date,
          accrual_count: accruals.size
        }
      )

      create_posting_links!(accruals, posting_batch)
      posting_batch
    end

    {
      status: :posted,
      account_id: account.id,
      amount_cents: amount_cents,
      accrual_count: accruals.size,
      posting_batch_id: batch.id
    }
  rescue StandardError => e
    { status: :errors, account_id: account.id, error: e.message }
  end

  def active_rules_by_product
    @active_rules_by_product ||= InterestRule
      .active_on(@business_date)
      .ordered
      .each_with_object({}) do |interest_rule, result|
        result[interest_rule.account_product_id] ||= interest_rule
      end
  end

  def cadence_due?(interest_rule)
    month_end = @business_date == @business_date.end_of_month
    return false unless month_end

    case interest_rule.posting_cadence
    when InterestRule::POSTING_CADENCE_QUARTERLY
      [ 3, 6, 9, 12 ].include?(@business_date.month)
    when InterestRule::POSTING_CADENCE_ANNUAL
      @business_date.month == 12
    else
      true
    end
  end

  def unposted_accruals_for(account)
    InterestAccrual
      .unposted
      .where(account_id: account.id, status: Bankcore::Enums::STATUS_POSTED)
      .where("accrual_date <= ?", @business_date)
      .order(:accrual_date, :id)
      .to_a
  end

  def create_posting_links!(accruals, batch)
    accruals.each do |accrual|
      InterestPostingApplication.find_or_create_by!(interest_accrual: accrual) do |application|
        application.posting_batch = batch
        application.posted_on = @business_date
      end
    end
  end

  def idempotency_key(account_id)
    "int-post-#{account_id}-#{@business_date}"
  end
end
