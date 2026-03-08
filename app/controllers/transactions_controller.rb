# frozen_string_literal: true

class TransactionsController < ApplicationController
  before_action :set_transaction, only: %i[show reverse]

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

    amount_cents = batch.posting_legs.sum(:amount_cents)
    threshold = Bankcore::REVERSAL_OVERRIDE_THRESHOLD_CENTS

    if amount_cents >= threshold
      override = OverrideRequest.usable.find_by(
        operational_transaction_id: @transaction.id,
        request_type: Bankcore::Enums::OVERRIDE_TYPE_REVERSAL
      )
      unless override
        redirect_to new_override_request_path(transaction_id: @transaction.id, request_type: "reversal"),
          alert: "Reversals of #{helpers.number_to_currency(threshold / 100.0)} or more require supervisor approval. Please request an override first."
        return
      end
      ReversalService.reverse!(posting_batch: batch, override_request: override)
    else
      ReversalService.reverse!(posting_batch: batch)
    end

    redirect_to transaction_path(@transaction), notice: "Transaction reversed successfully."
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

    amount_cents = (params[:amount].to_f * 100).round
    batch = ManualTransactionEntryService.entry!(
      transaction_code: params[:transaction_code],
      account_id: params[:account_id].presence,
      source_account_id: params[:source_account_id].presence,
      destination_account_id: params[:destination_account_id].presence,
      amount_cents: amount_cents,
      idempotency_key: params[:idempotency_key].presence,
      created_by_id: current_user&.id
    )
    redirect_to transaction_path(batch.operational_transaction_id), notice: "Transaction posted successfully."
  rescue PostingEngine::PostingError, PostingValidator::ValidationError => e
    @transaction_codes = TransactionCode.where(active: true).order(:code)
    @accounts = Account.where(status: Bankcore::Enums::STATUS_ACTIVE).order(:account_number)
    @business_date = BusinessDateService.current
    flash.now[:alert] = e.message
    render :new, status: :unprocessable_entity
  end

  private

  def set_transaction
    @transaction = BankingTransaction.find(params[:id])
  end

  def preview_transaction
    amount_cents = (params[:amount].to_f * 100).round
    @preview_legs = PostingEngine.preview!(
      transaction_code: params[:transaction_code],
      account_id: params[:account_id].presence,
      source_account_id: params[:source_account_id].presence,
      destination_account_id: params[:destination_account_id].presence,
      amount_cents: amount_cents,
      gl_account_id: params[:gl_account_id].presence
    )
    @transaction_code = params[:transaction_code]
    @amount_cents = amount_cents
    @params_for_confirm = params.permit(:transaction_code, :account_id, :source_account_id, :destination_account_id, :amount, :idempotency_key)
    render :preview
  rescue PostingEngine::PostingError, PostingValidator::ValidationError => e
    @transaction_codes = TransactionCode.where(active: true).order(:code)
    @accounts = Account.where(status: Bankcore::Enums::STATUS_ACTIVE).order(:account_number)
    @business_date = BusinessDateService.current
    flash.now[:alert] = e.message
    render :new, status: :unprocessable_entity
  end
end
