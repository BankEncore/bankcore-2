# frozen_string_literal: true

class InterestPostingService
  def self.post!(account_id:, amount_cents:, business_date: nil, idempotency_key: nil)
    new(account_id: account_id, amount_cents: amount_cents, business_date: business_date,
        idempotency_key: idempotency_key).post!
  end

  def initialize(account_id:, amount_cents:, business_date: nil, idempotency_key: nil)
    @account_id = account_id
    @amount_cents = amount_cents
    @business_date = business_date || BusinessDateService.current
    @idempotency_key = idempotency_key
  end

  def post!
    raise ArgumentError, "Amount must be positive" if @amount_cents.to_i <= 0

    PostingEngine.post!(
      transaction_code: "INT_POST",
      account_id: @account_id,
      amount_cents: @amount_cents,
      business_date: @business_date,
      idempotency_key: @idempotency_key
    )
  end
end
