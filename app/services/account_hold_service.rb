# frozen_string_literal: true

class AccountHoldService
  include Bankcore::Enums

  class HoldError < StandardError; end

  def self.place!(account_id:, amount_cents:, hold_type: HOLD_TYPE_MANUAL, reason_code: nil,
                  effective_on: nil, release_on: nil)
    new(
      account_id: account_id,
      amount_cents: amount_cents,
      hold_type: hold_type,
      reason_code: reason_code,
      effective_on: effective_on,
      release_on: release_on
    ).place!
  end

  def self.release!(account_hold:, released_at: nil)
    new(account_hold: account_hold, released_at: released_at).release!
  end

  def initialize(account_id: nil, amount_cents: nil, hold_type: nil, reason_code: nil,
                 effective_on: nil, release_on: nil, account_hold: nil, released_at: nil)
    @account_id = account_id
    @amount_cents = amount_cents
    @hold_type = hold_type
    @reason_code = reason_code
    @effective_on = effective_on || Date.current
    @release_on = release_on
    @account_hold = account_hold
    @released_at = released_at || Time.current
  end

  def place!
    raise HoldError, "Account not found" unless Account.exists?(@account_id)
    raise HoldError, "Amount must be positive" if @amount_cents.to_i <= 0
    raise HoldError, "Invalid hold type" unless HOLD_TYPES.include?(@hold_type)

    hold = AccountHold.create!(
      account_id: @account_id,
      hold_type: @hold_type,
      amount_cents: @amount_cents,
      status: HOLD_STATUS_ACTIVE,
      reason_code: @reason_code,
      effective_on: @effective_on,
      release_on: @release_on
    )
    BalanceRefreshService.refresh!(account_ids: [ @account_id ])
    hold
  end

  def release!
    raise HoldError, "Hold is not active" unless @account_hold.status == HOLD_STATUS_ACTIVE

    account_id = @account_hold.account_id
    @account_hold.update!(
      status: HOLD_STATUS_RELEASED,
      released_at: @released_at
    )
    BalanceRefreshService.refresh!(account_ids: [ account_id ])
    @account_hold
  end
end
