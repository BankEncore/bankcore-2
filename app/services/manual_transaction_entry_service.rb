# frozen_string_literal: true

class ManualTransactionEntryService
  def self.entry!(**params)
    new(**params).entry!
  end

  def initialize(transaction_code:, account_id: nil, source_account_id: nil, destination_account_id: nil,
                 amount_cents:, memo: nil, reason_text: nil, reference_number: nil, external_reference: nil,
                 idempotency_key: nil, created_by_id: nil, gl_account_id: nil, fee_type_id: nil,
                 ach_trace_number: nil, ach_effective_date: nil, ach_batch_reference: nil,
                 authorization_reference: nil, authorization_source: nil, business_date: nil)
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
    @fee_type_id = fee_type_id
    @ach_trace_number = ach_trace_number
    @ach_effective_date = ach_effective_date
    @ach_batch_reference = ach_batch_reference
    @authorization_reference = authorization_reference
    @authorization_source = authorization_source
    @business_date = business_date || BusinessDateService.current
  end

  def entry!
    request = TransactionEntry::Request.new(
      transaction_code: @transaction_code,
      account_id: @account_id,
      source_account_id: @source_account_id,
      destination_account_id: @destination_account_id,
      amount: format("%.2f", @amount_cents.to_i / 100.0),
      amount_cents: @amount_cents,
      memo: @memo,
      reason_text: @reason_text,
      reference_number: @reference_number,
      external_reference: @external_reference,
      idempotency_key: @idempotency_key,
      created_by_id: @created_by_id,
      business_date: @business_date,
      fee_type_id: @fee_type_id,
      ach_trace_number: @ach_trace_number,
      ach_effective_date: @ach_effective_date,
      ach_batch_reference: @ach_batch_reference,
      authorization_reference: @authorization_reference,
      authorization_source: @authorization_source,
      gl_account_id: @gl_account_id
    )

    TransactionEntry::Dispatcher.post!(request: request)
  end
end
