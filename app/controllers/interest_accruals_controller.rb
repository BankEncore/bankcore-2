# frozen_string_literal: true

class InterestAccrualsController < ApplicationController
  before_action -> { require_permission(:post_transactions) }, only: %i[run]

  def index
    load_workbench
    @interest_accruals = InterestAccrual
      .includes(:account)
      .order(accrual_date: :desc, created_at: :desc)
      .limit(100)

    @interest_accruals = @interest_accruals.where(account_id: params[:account_id]) if params[:account_id].present?
  end

  def run
    load_workbench
    @run_results = InterestAccrualRunnerService.run!(accrual_date: @business_date)
    @interest_accruals = InterestAccrual
      .includes(:account)
      .order(accrual_date: :desc, created_at: :desc)
      .limit(100)

    render :index
  rescue StandardError => e
    redirect_to interest_accruals_path, alert: "Interest accrual run failed: #{e.message}"
  end

  private

  def load_workbench
    @business_date = BusinessDateService.current
    @active_interest_rules = InterestRule.includes(:account_product).active_on(@business_date).ordered
  end
end
