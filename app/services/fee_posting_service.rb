# frozen_string_literal: true

class FeePostingService
  include Bankcore::Enums

  def self.assess!(account_id:, fee_type_id:, amount_cents: nil, business_date: nil, idempotency_key: nil)
    new(account_id: account_id, fee_type_id: fee_type_id, amount_cents: amount_cents,
        business_date: business_date, idempotency_key: idempotency_key).assess!
  end

  def initialize(account_id:, fee_type_id:, amount_cents: nil, business_date: nil, idempotency_key: nil)
    @account_id = account_id
    @fee_type_id = fee_type_id
    @amount_cents = amount_cents
    @business_date = business_date || BusinessDateService.current
    @idempotency_key = idempotency_key
  end

  def assess!
    fee_type = FeeType.find(@fee_type_id)
    amount = @amount_cents || fee_type.default_amount_cents
    raise ArgumentError, "Amount must be positive" if amount.to_i <= 0

    batch = PostingEngine.post!(
      transaction_code: "FEE_POST",
      account_id: @account_id,
      amount_cents: amount,
      business_date: @business_date,
      idempotency_key: @idempotency_key,
      gl_account_id: fee_type.gl_account_id
    )

    FeeAssessment.create!(
      account_id: @account_id,
      fee_type_id: @fee_type_id,
      posting_batch_id: batch.id,
      amount_cents: amount,
      assessed_on: @business_date,
      status: Bankcore::Enums::STATUS_POSTED
    )

    batch
  end
end
