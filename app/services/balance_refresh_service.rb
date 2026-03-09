# frozen_string_literal: true

class BalanceRefreshService
  def self.refresh!(account_ids:)
    new(account_ids: account_ids).refresh!
  end

  def self.rebuild!(account_id:)
    new(account_ids: [ account_id ]).rebuild!
  end

  def initialize(account_ids:)
    @account_ids = Array(account_ids).uniq
  end

  def refresh!
    @account_ids.each do |account_id|
      balance = compute_balance(account_id)
      average_balance = compute_average_balance(account_id)
      upsert_balance(account_id, balance, average_balance)
    end
  end

  def rebuild!
    refresh!
  end

  private

  def compute_balance(account_id)
    credits = AccountTransaction.where(account_id: account_id, direction: "credit").sum(:amount_cents)
    debits = AccountTransaction.where(account_id: account_id, direction: "debit").sum(:amount_cents)
    credits - debits
  end

  def active_holds_cents(account_id)
    AccountHold.where(
      account_id: account_id,
      status: Bankcore::Enums::HOLD_STATUS_ACTIVE
    ).sum(:amount_cents)
  end

  def compute_average_balance(account_id)
    running_balance = 0
    balance_points = AccountTransaction
      .where(account_id: account_id)
      .order(:posted_at, :id)
      .pluck(:direction, :amount_cents)
      .map do |direction, amount_cents|
        running_balance += direction == "credit" ? amount_cents : -amount_cents
      end

    return 0 if balance_points.empty?

    balance_points.sum / balance_points.size
  end

  def upsert_balance(account_id, balance_cents, average_balance_cents)
    holds_cents = active_holds_cents(account_id)
    available_cents = [ balance_cents - holds_cents, 0 ].max

    balance = AccountBalance.find_or_initialize_by(account_id: account_id)
    balance.assign_attributes(
      posted_balance_cents: balance_cents,
      available_balance_cents: available_cents,
      average_balance_cents: average_balance_cents,
      as_of_at: Time.current
    )
    balance.save!
  end
end
