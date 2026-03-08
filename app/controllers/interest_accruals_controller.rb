# frozen_string_literal: true

class InterestAccrualsController < ApplicationController
  def index
    @interest_accruals = InterestAccrual
      .includes(:account)
      .order(accrual_date: :desc, created_at: :desc)
      .limit(100)

    @interest_accruals = @interest_accruals.where(account_id: params[:account_id]) if params[:account_id].present?
  end
end
