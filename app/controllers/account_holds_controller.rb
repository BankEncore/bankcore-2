# frozen_string_literal: true

class AccountHoldsController < ApplicationController
  before_action :set_account, only: %i[new create]
  before_action :set_hold, only: :release

  def new
    @hold = AccountHold.new(account: @account, hold_type: Bankcore::Enums::HOLD_TYPE_MANUAL)
  end

  def create
    hold = AccountHoldService.place!(
      account_id: @account.id,
      amount_cents: (params[:amount].to_f * 100).round,
      hold_type: params[:hold_type].presence || Bankcore::Enums::HOLD_TYPE_MANUAL,
      reason_code: params[:reason_code].presence,
      effective_on: params[:effective_on].presence&.to_date || Date.current,
      release_on: params[:release_on].presence&.to_date
    )
    redirect_to account_path(@account), notice: "Hold placed successfully."
  rescue AccountHoldService::HoldError => e
    @hold = AccountHold.new(account: @account, hold_type: params[:hold_type])
    flash.now[:alert] = e.message
    render :new, status: :unprocessable_entity
  end

  def release
    AccountHoldService.release!(account_hold: @hold)
    redirect_to account_path(@hold.account), notice: "Hold released."
  rescue AccountHoldService::HoldError => e
    redirect_to account_path(@hold.account), alert: "Release failed: #{e.message}"
  end

  private

  def set_account
    @account = Account.find(params[:account_id])
  end

  def set_hold
    @hold = AccountHold.find(params[:id])
  end
end
