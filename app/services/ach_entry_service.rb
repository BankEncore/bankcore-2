# frozen_string_literal: true

class AchEntryService
  def self.post!(**params)
    new(**params).post!
  end

  def initialize(transaction_code:, account_id:, amount_cents:, business_date: nil, memo: nil, reason_text: nil,
                 reference_number: nil, external_reference: nil, idempotency_key: nil, created_by_id: nil,
                 ach_trace_number:, ach_effective_date:, ach_batch_reference:, ach_company_name: nil,
                 ach_identification_number: nil, authorization_reference: nil, authorization_source: nil)
    @transaction_code = transaction_code
    @account_id = account_id
    @amount_cents = amount_cents
    @business_date = business_date || BusinessDateService.current
    @memo = memo
    @reason_text = reason_text
    @reference_number = reference_number
    @external_reference = external_reference
    @idempotency_key = idempotency_key
    @created_by_id = created_by_id
    @ach_trace_number = ach_trace_number
    @ach_effective_date = ach_effective_date
    @ach_batch_reference = ach_batch_reference
    @ach_company_name = ach_company_name
    @ach_identification_number = ach_identification_number
    @authorization_reference = authorization_reference
    @authorization_source = authorization_source
  end

  def post!
    ActiveRecord::Base.transaction do
      posting_batch = PostingEngine.post!(
        transaction_code: @transaction_code,
        account_id: @account_id,
        amount_cents: @amount_cents,
        business_date: @business_date,
        memo: @memo,
        reason_text: @reason_text,
        reference_number: @reference_number,
        external_reference: @external_reference,
        idempotency_key: @idempotency_key,
        created_by_id: @created_by_id,
        idempotency_context: ach_idempotency_context
      )

      persist_references!(posting_batch.operational_transaction)
      posting_batch
    end
  end

  private

  def ach_idempotency_context
    {
      service: "ach_entry",
      ach_trace_number: @ach_trace_number,
      ach_effective_date: @ach_effective_date&.to_date&.iso8601,
      ach_batch_reference: @ach_batch_reference,
      authorization_reference: @authorization_reference,
      authorization_source: @authorization_source
    }.compact
  end

  def persist_references!(operational_transaction)
    reference_attributes.each do |reference_type, reference_value|
      TransactionReference.find_or_create_by!(
        operational_transaction: operational_transaction,
        reference_type: reference_type,
        reference_value: reference_value
      )
    end
  end

  def reference_attributes
    {
      TransactionReference::REFERENCE_TYPE_ACH_TRACE_NUMBER => @ach_trace_number,
      TransactionReference::REFERENCE_TYPE_ACH_EFFECTIVE_DATE => @ach_effective_date&.to_date&.iso8601,
      TransactionReference::REFERENCE_TYPE_ACH_BATCH_REFERENCE => @ach_batch_reference,
      TransactionReference::REFERENCE_TYPE_ACH_COMPANY_NAME => @ach_company_name,
      TransactionReference::REFERENCE_TYPE_ACH_IDENTIFICATION_NUMBER => @ach_identification_number,
      TransactionReference::REFERENCE_TYPE_AUTHORIZATION_REFERENCE => @authorization_reference,
      TransactionReference::REFERENCE_TYPE_AUTHORIZATION_SOURCE => @authorization_source
    }.compact
  end
end
