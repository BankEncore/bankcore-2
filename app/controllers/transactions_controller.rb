# frozen_string_literal: true

class TransactionsController < ApplicationController
  ACCOUNT_FIELD_NAMES = %i[account_id source_account_id destination_account_id].freeze

  TRANSACTION_FORM_FIELDS = %i[
    transaction_code
    account_id
    source_account_id
    destination_account_id
    amount
    fee_type_id
    memo
    reason_text
    reference_number
    external_reference
    idempotency_key
    ach_trace_number
    ach_effective_date
    ach_batch_reference
    ach_company_name
    ach_identification_number
    check_number
    confirmation_number
    override_request_id
    authorization_reference
    authorization_source
  ].freeze

  before_action :set_transaction, only: %i[show reverse reverse_preview]
  before_action -> { require_permission(:post_transactions) }, only: %i[new create]
  before_action -> { require_permission(:reverse_transactions) }, only: %i[reverse reverse_preview]

  def index
    @transactions = BankingTransaction
      .includes(:branch, :posting_batch, :transaction_references)
      .order(created_at: :desc)
      .limit(100)
  end

  def show
    @posting_batch = @transaction.posting_batch
    @transaction_exceptions = @transaction.transaction_exceptions.includes(:resolved_by).order(created_at: :desc)
    @transaction_references = @transaction.transaction_references.order(:reference_type, :id)
    @posting_legs = @posting_batch&.posting_legs&.includes(:account, :gl_account) || []
    @transaction.check_items.includes(:account).load if @transaction.transaction_type == "CHK_POST"
  end

  def reverse
    batch = @transaction.posting_batch
    raise ActiveRecord::RecordNotFound, "No posting batch" unless batch

    ReversalService.reverse!(posting_batch: batch)
    redirect_to transaction_path(@transaction), notice: "Transaction reversed successfully."
  rescue ReversalService::OverrideRequiredError => e
    redirect_to new_override_request_path(transaction_id: @transaction.id, request_type: "reversal"), alert: e.message
  rescue ReversalService::ReversalError, OverrideRequestService::OverrideError => e
    redirect_to transaction_path(@transaction), alert: "Reversal failed: #{e.message}"
  end

  def new
    @preselected_account_id = params[:account_id]
    load_form_dependencies
  end

  def create
    if params[:preview].present?
      preview_transaction
      return
    end

    request = transaction_entry_request
    batch = TransactionEntry::Dispatcher.post!(request: request)
    redirect_to transaction_path(batch.operational_transaction_id), notice: "Transaction posted successfully."
  rescue TransactionEntry::CheckOverdraftOverrideRequiredError => e
    redirect_to new_override_request_path(
      request_type: Bankcore::Enums::OVERRIDE_TYPE_CHECK_OVERDRAFT,
      account_id: e.account_id,
      amount_cents: e.amount_cents,
      check_number: e.check_number
    ), alert: e.message
  rescue PostingEngine::PostingError, PostingValidator::ValidationError, TransactionEntry::Error, ArgumentError => e
    load_form_dependencies
    flash.now[:alert] = e.message
    render :new, status: :unprocessable_entity
  end

  def reverse_preview
    @posting_batch = @transaction.posting_batch
    raise ActiveRecord::RecordNotFound, "No posting batch" unless @posting_batch

    @preview_legs = @posting_batch.posting_legs.includes(:account, :gl_account).order(:position).map do |leg|
      {
        leg_type: leg.leg_type == Bankcore::Enums::LEG_TYPE_DEBIT ? Bankcore::Enums::LEG_TYPE_CREDIT : Bankcore::Enums::LEG_TYPE_DEBIT,
        ledger_scope: leg.ledger_scope,
        account: leg.account,
        gl_account: leg.gl_account,
        amount_cents: leg.amount_cents
      }
    end
    @economic_amount_cents = @posting_batch.posting_legs.minimum(:amount_cents).to_i
    @override_threshold_cents = Bankcore::REVERSAL_OVERRIDE_THRESHOLD_CENTS
    @override_required = @economic_amount_cents >= @override_threshold_cents
  end

  private

  def set_transaction
    @transaction = BankingTransaction.find(params[:id])
  end

  def preview_transaction
    request = transaction_entry_request
    preview = TransactionEntry::PreviewService.preview!(request: request)
    @preview_legs = preview[:legs]
    @transaction_code = request.transaction_code
    @amount_cents = preview[:amount_cents]
    @params_for_confirm = request.to_form_params
    @preview_metadata = preview[:metadata]
    @preview_context_rows = preview[:context_rows]
    render :preview
  rescue PostingEngine::PostingError, PostingValidator::ValidationError, TransactionEntry::Error, ArgumentError => e
    load_form_dependencies
    flash.now[:alert] = e.message
    render :new, status: :unprocessable_entity
  end

  def transaction_form_params
    raw_params = params[:transaction]
    return {}.with_indifferent_access unless raw_params.respond_to?(:[])

    TRANSACTION_FORM_FIELDS.each_with_object({}.with_indifferent_access) do |field, result|
      result[field] = raw_params[field]
    end
  end

  def load_form_dependencies
    @transaction_codes = TransactionCode.where(active: true, code: TransactionEntry::Request::MANUAL_ENTRY_CODES).order(:code)
    @fee_types = FeeType.where(status: Bankcore::Enums::STATUS_ACTIVE).order(:name)
    @business_date = BusinessDateService.current
    load_selected_accounts
  end

  def transaction_entry_request
    params_hash = transaction_form_params
    account_numbers = transfer_account_numbers_for_memo_default(params_hash)

    TransactionEntry::Request.from_form(
      raw_params: params_hash,
      created_by_id: current_user&.id,
      business_date: BusinessDateService.current,
      account_numbers: account_numbers
    )
  end

  def transfer_account_numbers_for_memo_default(params_hash)
    return nil unless params_hash[:transaction_code].to_s == "XFER_INTERNAL"
    return nil if params_hash[:memo].to_s.strip.present?

    source_id = params_hash[:source_account_id].presence&.to_i
    dest_id = params_hash[:destination_account_id].presence&.to_i
    return nil unless source_id && dest_id

    numbers_by_id = Account
      .where(id: [ source_id, dest_id ])
      .pluck(:id, :account_number)
      .to_h
    {
      source: numbers_by_id[source_id],
      destination: numbers_by_id[dest_id]
    }
  end

  def load_selected_accounts
    selected_ids = ACCOUNT_FIELD_NAMES.index_with do |field_name|
      if field_name == :account_id
        @preselected_account_id.presence || transaction_form_params[field_name].presence
      else
        transaction_form_params[field_name].presence
      end
    end.compact

    accounts_by_id = Account
      .where(id: selected_ids.values, status: Bankcore::Enums::STATUS_ACTIVE)
      .includes(:account_product, :branch, :account_balances, account_owners: :party)
      .index_by(&:id)

    @selected_account = accounts_by_id[selected_ids[:account_id].to_i]
    @selected_source_account = accounts_by_id[selected_ids[:source_account_id].to_i]
    @selected_destination_account = accounts_by_id[selected_ids[:destination_account_id].to_i]
    @selected_account_payload = account_context_payload(@selected_account)
    @selected_source_account_payload = account_context_payload(@selected_source_account)
    @selected_destination_account_payload = account_context_payload(@selected_destination_account)
  end

  def account_context_payload(account)
    return if account.blank?

    AccountContextPayloadBuilder.build(account)
  end
end
