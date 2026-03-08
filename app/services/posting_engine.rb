# frozen_string_literal: true

require "digest"

class PostingEngine
  include Bankcore::Enums

  class PostingError < StandardError; end
  class IdempotencyConflictError < PostingError; end

  def self.post!(**params)
    new(**params).post!
  end

  def self.preview!(**params)
    new(**params).preview!
  end

  def initialize(transaction_code:, account_id: nil, source_account_id: nil, destination_account_id: nil,
                 amount_cents:, business_date: nil, idempotency_key: nil, created_by_id: nil,
                 gl_account_id: nil, reversal_of_batch_id: nil, idempotency_context: nil)
    @transaction_code = transaction_code
    @account_id = account_id
    @source_account_id = source_account_id
    @destination_account_id = destination_account_id
    @amount_cents = amount_cents
    @business_date = business_date || BusinessDateService.current
    @idempotency_key = idempotency_key
    @created_by_id = created_by_id
    @gl_account_id = gl_account_id
    @reversal_of_batch_id = reversal_of_batch_id
    @idempotency_context = idempotency_context
  end

  def post!
    existing_batch = matching_idempotent_batch
    return existing_batch if existing_batch.present?

    ActiveRecord::Base.transaction do
      build_and_validate_legs!
      create_posted_records!
    end
  rescue ActiveRecord::RecordNotUnique
    existing_batch = matching_idempotent_batch
    return existing_batch if existing_batch.present?

    raise
  end

  def preview!
    build_and_validate_legs!
    @legs.map do |leg|
      {
        leg_type: leg[:leg_type],
        ledger_scope: leg[:ledger_scope],
        account: leg[:account_id] ? Account.find_by(id: leg[:account_id]) : nil,
        gl_account: leg[:gl_account_id] ? GlAccount.find_by(id: leg[:gl_account_id]) : nil,
        amount_cents: leg[:amount_cents]
      }
    end
  end

  private

  def matching_idempotent_batch
    return false if @idempotency_key.blank?

    batch = PostingBatch.find_by(idempotency_key: @idempotency_key, status: STATUS_POSTED)
    return false unless batch
    return batch if idempotency_payload_matches?(batch)

    raise IdempotencyConflictError,
      "Idempotency key #{@idempotency_key} has already been used for a different request"
  end

  def build_and_validate_legs!
    template = PostingTemplate.joins(:transaction_code)
      .find_by(transaction_codes: { code: @transaction_code }, posting_templates: { active: true })

    raise PostingError, "No posting template for #{@transaction_code}" unless template

    @legs = template.posting_template_legs.order(:position).map do |tl|
      build_leg(tl)
    end

    PostingValidator.new(legs: @legs, business_date: @business_date).validate!
  end

  def build_leg(template_leg)
    account_id = resolve_account_id(template_leg.account_source)
    gl_account_id = template_leg.gl_account_id || @gl_account_id
    ledger_scope = [ ACCOUNT_SOURCE_CUSTOMER, ACCOUNT_SOURCE_SOURCE, ACCOUNT_SOURCE_DESTINATION ].include?(template_leg.account_source) ? LEDGER_SCOPE_ACCOUNT : LEDGER_SCOPE_GL

    # PostingLeg requires exactly one of gl_account or account
    final_account_id = ledger_scope == LEDGER_SCOPE_ACCOUNT ? account_id : nil
    final_gl_account_id = ledger_scope == LEDGER_SCOPE_GL ? gl_account_id : nil

    {
      leg_type: template_leg.leg_type,
      ledger_scope: ledger_scope,
      account_id: final_account_id,
      gl_account_id: final_gl_account_id,
      amount_cents: @amount_cents,
      currency_code: Bankcore::DEFAULT_CURRENCY
    }
  end

  def resolve_account_id(source)
    case source
    when ACCOUNT_SOURCE_CUSTOMER then @account_id
    when ACCOUNT_SOURCE_SOURCE then @source_account_id
    when ACCOUNT_SOURCE_DESTINATION then @destination_account_id
    else nil
    end
  end

  def create_posted_records!
    branch_id = resolve_branch_id
    operational_txn = BankingTransaction.create!(
      transaction_type: @transaction_code,
      channel: "back_office",
      branch_id: branch_id,
      status: STATUS_POSTED,
      business_date: @business_date,
      initiated_at: Time.current,
      posted_at: Time.current,
      created_by_id: @created_by_id
    )

    batch = PostingBatch.create!(
      operational_transaction_id: operational_txn.id,
      status: STATUS_POSTED,
      business_date: @business_date,
      posted_at: Time.current,
      transaction_code: @transaction_code,
      reversal_of_batch_id: @reversal_of_batch_id,
      **idempotency_attributes
    )

    @legs.each_with_index do |leg, idx|
      PostingLeg.create!(
        posting_batch_id: batch.id,
        leg_type: leg[:leg_type],
        ledger_scope: leg[:ledger_scope],
        account_id: leg[:account_id],
        gl_account_id: leg[:gl_account_id],
        amount_cents: leg[:amount_cents],
        currency_code: leg[:currency_code],
        position: idx
      )
    end

    JournalProjector.project!(posting_batch: batch)
    AccountProjector.project!(posting_batch: batch)

    AuditEmissionService.emit!(
      event_type: @reversal_of_batch_id ? "reversal_posted" : "posting_succeeded",
      action: "post",
      target: batch,
      business_date: @business_date,
      metadata: {
        transaction_code: @transaction_code,
        reversal_of_batch_id: @reversal_of_batch_id
      }
    )

    batch
  end

  def resolve_branch_id
    account = Account.find_by(id: @account_id || @source_account_id || @destination_account_id)
    account&.branch_id || Branch.first&.id
  end

  def idempotency_attributes
    return {} if @idempotency_key.blank?

    {
      idempotency_key: @idempotency_key,
      idempotency_fingerprint: idempotency_fingerprint,
      idempotency_payload_json: idempotency_payload_json
    }
  end

  def idempotency_payload_matches?(batch)
    return true if batch.idempotency_fingerprint.blank?

    batch.idempotency_fingerprint == idempotency_fingerprint
  end

  def idempotency_fingerprint
    @idempotency_fingerprint ||= Digest::SHA256.hexdigest(idempotency_payload_json)
  end

  def idempotency_payload_json
    @idempotency_payload_json ||= JSON.generate(canonicalize_value(semantic_idempotency_payload))
  end

  def semantic_idempotency_payload
    payload = {
      transaction_code: @transaction_code,
      account_id: @account_id,
      source_account_id: @source_account_id,
      destination_account_id: @destination_account_id,
      amount_cents: @amount_cents,
      business_date: @business_date&.to_date&.iso8601,
      gl_account_id: @gl_account_id,
      reversal_of_batch_id: @reversal_of_batch_id
    }
    payload[:context] = @idempotency_context if @idempotency_context.present?
    payload.compact
  end

  def canonicalize_value(value)
    case value
    when Hash
      value.keys.sort_by(&:to_s).each_with_object({}) do |key, result|
        result[key.to_s] = canonicalize_value(value[key])
      end
    when Array
      value.map { |item| canonicalize_value(item) }
    when Date
      value.iso8601
    when Time, ActiveSupport::TimeWithZone
      value.iso8601
    else
      value
    end
  end
end
