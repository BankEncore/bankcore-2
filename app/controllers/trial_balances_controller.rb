# frozen_string_literal: true

class TrialBalancesController < ApplicationController
  def index
    load_report
    @summary_rows = @trial_balance_query.summary_rows
    @totals = @trial_balance_query.totals
  end

  def show
    load_report
    @gl_account = GlAccount.find(params[:id])
    @summary_row = @trial_balance_query.summary_row_for(@gl_account.id)
    @detail_rows = @trial_balance_query.detail_rows(gl_account_id: @gl_account.id)
    @detail_totals = @trial_balance_query.detail_totals(gl_account_id: @gl_account.id)
  end

  private

  def load_report
    @business_date = resolved_business_date
    @include_zero = include_zero?
    @trial_balance_query = TrialBalanceQuery.new(
      business_date: @business_date,
      include_zero: @include_zero
    )
  end

  def resolved_business_date
    return BusinessDateService.current if params[:business_date].blank?

    Date.iso8601(params[:business_date])
  rescue ArgumentError
    BusinessDateService.current
  end

  def include_zero?
    params[:include_zero] != "0"
  end
end
