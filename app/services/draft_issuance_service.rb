# frozen_string_literal: true

class DraftIssuanceService
  class DraftIssuanceError < StandardError; end

  def self.post!(**params)
    new(**params).post!
  end

  def initialize(instrument_type:, remitter_party_id:, account_id:, amount_cents:, payee_name:, branch_id:,
                 memo: nil, expires_at: nil, business_date: nil, reference_number: nil, idempotency_key: nil,
                 created_by_id: nil)
    @instrument_type = instrument_type
    @remitter_party_id = remitter_party_id
    @account_id = account_id
    @amount_cents = amount_cents
    @payee_name = payee_name
    @branch_id = branch_id
    @memo = memo
    @expires_at = expires_at
    @business_date = business_date || BusinessDateService.current
    @reference_number = reference_number
    @idempotency_key = idempotency_key
    @created_by_id = created_by_id
  end

  def post!
    validate_account_remitter_relationship!
    instrument_number = BankDraftSequenceService.next_number!(branch_id: @branch_id, instrument_type: @instrument_type)

    ActiveRecord::Base.transaction do
      posting_batch = PostingEngine.post!(
        transaction_code: "DRAFT_ISSUE",
        account_id: @account_id,
        amount_cents: @amount_cents,
        business_date: @business_date,
        memo: @memo,
        reference_number: @reference_number,
        idempotency_key: @idempotency_key,
        created_by_id: @created_by_id,
        idempotency_context: idempotency_context(instrument_number)
      )

      persist_instrument_reference!(posting_batch.operational_transaction, instrument_number)
      create_bank_draft!(posting_batch, instrument_number)
      posting_batch
    end
  end

  private

  def validate_account_remitter_relationship!
    return unless @account_id.present?

    account = Account.find_by(id: @account_id)
    raise DraftIssuanceError, "Account not found" unless account

    unless account.parties.exists?(id: @remitter_party_id)
      raise DraftIssuanceError, "Account must belong to or be valid for the remitter party"
    end
  end

  def idempotency_context(instrument_number)
    {
      service: "draft_issuance",
      instrument_type: @instrument_type,
      instrument_number: instrument_number,
      remitter_party_id: @remitter_party_id,
      account_id: @account_id,
      amount_cents: @amount_cents,
      payee_name: @payee_name,
      issue_date: @business_date&.to_date&.iso8601
    }.compact
  end

  def persist_instrument_reference!(operational_transaction, instrument_number)
    return unless operational_transaction

    TransactionReference.find_or_create_by!(
      operational_transaction: operational_transaction,
      reference_type: TransactionReference::REFERENCE_TYPE_INSTRUMENT_NUMBER,
      reference_value: instrument_number
    )
  end

  def create_bank_draft!(posting_batch, instrument_number)
    BankDraft.create!(
      instrument_type: @instrument_type,
      instrument_number: instrument_number,
      amount_cents: @amount_cents,
      currency_code: "USD",
      payee_name: @payee_name,
      issue_date: @business_date,
      status: BankDraft::STATUS_ISSUED,
      memo: @memo,
      expires_at: @expires_at,
      remitter_party_id: @remitter_party_id,
      account_id: @account_id,
      branch_id: @branch_id,
      issued_by_id: @created_by_id,
      operational_transaction_id: posting_batch.operational_transaction_id,
      posting_batch_id: posting_batch.id
    )
  end
end
