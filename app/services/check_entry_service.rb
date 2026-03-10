# frozen_string_literal: true

class CheckEntryService
  def self.post!(**params)
    new(**params).post!
  end

  def initialize(transaction_code:, account_id:, amount_cents:, business_date: nil, memo: nil, reason_text: nil,
                 reference_number: nil, external_reference: nil, idempotency_key: nil, created_by_id: nil,
                 check_number:, override_request_id: nil)
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
    @check_number = check_number
    @override_request_id = override_request_id
  end

  def post!
    consume_override_if_present!
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
        idempotency_context: check_idempotency_context
      )

      persist_references!(posting_batch.operational_transaction)
      create_check_item!(posting_batch)
      assess_od_fee_if_needed!(posting_batch)
      posting_batch
    end
  end

  private

  def consume_override_if_present!
    return unless @override_request_id.present?

    override = OverrideRequest.usable.find_by(id: @override_request_id, request_type: Bankcore::Enums::OVERRIDE_TYPE_CHECK_OVERDRAFT)
    return unless override

    OverrideRequestService.use!(
      override_request: override,
      context_for_validation: { account_id: @account_id, amount_cents: @amount_cents, check_number: @check_number }
    )
  end

  def check_idempotency_context
    {
      service: "check_entry",
      account_id: @account_id,
      check_number: @check_number,
      amount_cents: @amount_cents
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
      TransactionReference::REFERENCE_TYPE_CHECK_NUMBER => @check_number
    }.compact
  end

  def create_check_item!(posting_batch)
    CheckItem.create!(
      account_id: @account_id,
      check_number: @check_number,
      amount_cents: @amount_cents,
      status: CheckItem::STATUS_POSTED,
      operational_transaction_id: posting_batch.operational_transaction_id,
      posting_batch_id: posting_batch.id,
      business_date: @business_date
    )
  end

  def assess_od_fee_if_needed!(posting_batch)
    account = Account.find_by(id: @account_id)
    return unless account

    overdraft_allowed = account.deposit_account&.overdraft_policy == "allow" || (account.deposit_account&.overdraft_policy.blank? && account.account_product&.allow_overdraft)
    return unless overdraft_allowed

    balance = account.account_balances.pick(:available_balance_cents) || 0
    return if balance > 0

    od_rule = od_fee_rule_for(account)
    return unless od_rule

    FeePostingService.assess!(
      account_id: @account_id,
      fee_type_id: od_rule.fee_type_id,
      fee_rule_id: od_rule.id,
      amount_cents: od_rule.amount_cents_for_assessment,
      business_date: @business_date,
      gl_account_id: od_rule.gl_account_id_for_posting
    )
  end

  def od_fee_rule_for(account)
    return nil unless account.account_product_id

    FeeRule
      .joins(:fee_type)
      .where(
        account_product_id: account.account_product_id,
        fee_types: { code: "OD" }
      )
      .where("fee_rules.effective_on IS NULL OR fee_rules.effective_on <= ?", @business_date)
      .where("fee_rules.ends_on IS NULL OR fee_rules.ends_on >= ?", @business_date)
      .order(priority: :asc)
      .first
  end
end
