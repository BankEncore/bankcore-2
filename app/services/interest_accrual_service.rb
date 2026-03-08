# frozen_string_literal: true

class InterestAccrualService
  include Bankcore::Enums

  def self.accrue!(account_id:, amount_cents:, accrual_date: nil, idempotency_key: nil)
    new(account_id: account_id, amount_cents: amount_cents, accrual_date: accrual_date,
        idempotency_key: idempotency_key).accrue!
  end

  def initialize(account_id:, amount_cents:, accrual_date: nil, idempotency_key: nil)
    @account_id = account_id
    @amount_cents = amount_cents
    @accrual_date = accrual_date || BusinessDateService.current
    @idempotency_key = idempotency_key
  end

  def accrue!
    raise ArgumentError, "Amount must be non-negative" if @amount_cents.to_i < 0

    batch = PostingEngine.post!(
      transaction_code: "INT_ACCRUAL",
      account_id: nil,
      amount_cents: @amount_cents,
      business_date: @accrual_date,
      idempotency_key: @idempotency_key
    )

    InterestAccrual.create!(
      account_id: @account_id,
      accrual_date: @accrual_date,
      amount_cents: @amount_cents,
      posting_batch_id: batch.id,
      status: Bankcore::Enums::STATUS_POSTED
    )

    batch
  end
end
