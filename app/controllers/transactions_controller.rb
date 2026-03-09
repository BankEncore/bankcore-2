# frozen_string_literal: true

class TransactionsController < ApplicationController
  TRANSACTION_FORM_FIELDS = %i[
    transaction_code
    account_id
    source_account_id
    destination_account_id
    amount
    memo
    reason_text
    reference_number
    external_reference
    idempotency_key
  ].freeze

  before_action :set_transaction, only: %i[show reverse]
  before_action -> { require_permission(:reverse_transactions) }, only: %i[reverse]

  def index
    @transactions = BankingTransaction
      .includes(:branch, :posting_batch)
      .order(created_at: :desc)
      .limit(100)
  end

  def show
    @posting_batch = @transaction.posting_batch
    @posting_legs = @posting_batch&.posting_legs&.includes(:account, :gl_account) || []
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
    @transaction_codes = TransactionCode.where(active: true).order(:code)
    @accounts = Account.where(status: Bankcore::Enums::STATUS_ACTIVE).order(:account_number)
    @business_date = BusinessDateService.current
    @preselected_account_id = params[:account_id]
  end

  def create
    if params[:preview].present?
      preview_transaction
      return
    end

    form_params = transaction_form_params
    amount_cents = (form_params[:amount].to_f * 100).round
    batch = ManualTransactionEntryService.entry!(
      transaction_code: form_params[:transaction_code],
      account_id: form_params[:account_id].presence,
      source_account_id: form_params[:source_account_id].presence,
      destination_account_id: form_params[:destination_account_id].presence,
      amount_cents: amount_cents,
      memo: form_params[:memo].presence,
      reason_text: form_params[:reason_text].presence,
      reference_number: form_params[:reference_number].presence,
      external_reference: form_params[:external_reference].presence,
      idempotency_key: form_params[:idempotency_key].presence,
      created_by_id: current_user&.id
    )
    redirect_to transaction_path(batch.operational_transaction_id), notice: "Transaction posted successfully."
  rescue PostingEngine::PostingError, PostingValidator::ValidationError => e
    load_form_dependencies
    flash.now[:alert] = e.message
    render :new, status: :unprocessable_entity
  end

  private

  def set_transaction
    @transaction = BankingTransaction.find(params[:id])
  end

  def preview_transaction
    form_params = transaction_form_params
    amount_cents = (form_params[:amount].to_f * 100).round
    @preview_legs = PostingEngine.preview!(
      transaction_code: form_params[:transaction_code],
      account_id: form_params[:account_id].presence,
      source_account_id: form_params[:source_account_id].presence,
      destination_account_id: form_params[:destination_account_id].presence,
      amount_cents: amount_cents,
      memo: form_params[:memo].presence,
      reason_text: form_params[:reason_text].presence,
      reference_number: form_params[:reference_number].presence,
      external_reference: form_params[:external_reference].presence,
      gl_account_id: params[:gl_account_id].presence
    )
    @transaction_code = form_params[:transaction_code]
    @amount_cents = amount_cents
    @params_for_confirm = {
      transaction_code: form_params[:transaction_code],
      account_id: form_params[:account_id].presence,
      source_account_id: form_params[:source_account_id].presence,
      destination_account_id: form_params[:destination_account_id].presence,
      amount: form_params[:amount],
      memo: form_params[:memo].presence,
      reason_text: form_params[:reason_text].presence,
      reference_number: form_params[:reference_number].presence,
      external_reference: form_params[:external_reference].presence,
      idempotency_key: form_params[:idempotency_key].presence
    }.compact
    @preview_metadata = @params_for_confirm.slice(:memo, :reason_text, :reference_number, :external_reference, :idempotency_key)
    render :preview
  rescue PostingEngine::PostingError, PostingValidator::ValidationError => e
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
    @transaction_codes = TransactionCode.where(active: true).order(:code)
    @accounts = Account.where(status: Bankcore::Enums::STATUS_ACTIVE).order(:account_number)
    @business_date = BusinessDateService.current
  end
end
