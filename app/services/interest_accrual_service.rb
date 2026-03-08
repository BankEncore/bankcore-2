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
      idempotency_key: @idempotency_key,
      idempotency_context: {
        service: "interest_accrual",
        account_id: @account_id
      }
    )

    InterestAccrual.find_or_create_by!(posting_batch_id: batch.id) do |accrual|
      accrual.account_id = @account_id
      accrual.accrual_date = @accrual_date
      accrual.amount_cents = @amount_cents
      accrual.status = Bankcore::Enums::STATUS_POSTED
    end

    batch
  end
end
