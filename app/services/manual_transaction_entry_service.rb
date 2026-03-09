# frozen_string_literal: true

class ManualTransactionEntryService
  def self.entry!(**params)
    new(**params).entry!
  end

  def initialize(transaction_code:, account_id: nil, source_account_id: nil, destination_account_id: nil,
                 amount_cents:, memo: nil, reason_text: nil, reference_number: nil, external_reference: nil,
                 idempotency_key: nil, created_by_id: nil, gl_account_id: nil)
    @transaction_code = transaction_code
    @account_id = account_id
    @source_account_id = source_account_id
    @destination_account_id = destination_account_id
    @amount_cents = amount_cents
    @memo = memo
    @reason_text = reason_text
    @reference_number = reference_number
    @external_reference = external_reference
    @idempotency_key = idempotency_key
    @created_by_id = created_by_id
    @gl_account_id = gl_account_id
  end

  def entry!
    PostingEngine.post!(
      transaction_code: @transaction_code,
      account_id: @account_id,
      source_account_id: @source_account_id,
      destination_account_id: @destination_account_id,
      amount_cents: @amount_cents,
      memo: @memo,
      reason_text: @reason_text,
      reference_number: @reference_number,
      external_reference: @external_reference,
      idempotency_key: @idempotency_key,
      created_by_id: @created_by_id,
      gl_account_id: @gl_account_id
    )
  end
end
