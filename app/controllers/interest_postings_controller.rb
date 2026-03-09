# frozen_string_literal: true

class InterestPostingsController < ApplicationController
  before_action -> { require_permission(:post_transactions) }, only: %i[create]

  def index
    load_workbench
  end

  def create
    load_workbench
    @run_results = InterestPostingRunnerService.run!(business_date: @business_date)
    render :index
  rescue StandardError => e
    redirect_to interest_postings_path, alert: "Interest posting run failed: #{e.message}"
  end

  private

  def load_workbench
    @business_date = BusinessDateService.current
    @due_accounts = due_accounts
  end

  def due_accounts
    active_rules = InterestRule.active_on(@business_date).ordered.each_with_object({}) do |rule, result|
      result[rule.account_product_id] ||= rule
    end
    return [] if active_rules.empty?

    Account
      .includes(:account_product, :deposit_account)
      .joins(:deposit_account)
      .where(status: Bankcore::Enums::STATUS_ACTIVE, account_product_id: active_rules.keys)
      .where(deposit_accounts: { interest_bearing: true })
      .map do |account|
        accruals = InterestAccrual
          .unposted
          .where(account_id: account.id, status: Bankcore::Enums::STATUS_POSTED)
          .where("accrual_date <= ?", @business_date)
          .order(:accrual_date, :id)

        next if accruals.empty?

        {
          account: account,
          posting_cadence: active_rules[account.account_product_id]&.posting_cadence,
          accrual_count: accruals.size,
          amount_cents: accruals.sum(:amount_cents)
        }
      end.compact
  end
end
