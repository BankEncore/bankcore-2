# frozen_string_literal: true

class BankDraftsController < ApplicationController
  before_action -> { require_permission(:post_transactions) }, only: %i[new create]
  before_action -> { require_permission(:reverse_transactions) }, only: %i[void]
  before_action -> { require_permission(:post_transactions) }, only: %i[clear]
  before_action :set_bank_draft, only: %i[show void clear]
  before_action :set_form_options, only: %i[new create]

  def index
    @bank_drafts = BankDraft
      .includes(:branch, :remitter_party, :account)
      .order(issue_date: :desc, id: :desc)
      .limit(100)
  end

  def show
    @transaction = @bank_draft.operational_transaction
    @posting_batch = @bank_draft.posting_batch
  end

  def void
    VoidDraftService.void!(
      bank_draft: @bank_draft,
      void_reason: params[:void_reason],
      voided_by_id: current_user&.id
    )
    redirect_to bank_draft_path(@bank_draft), notice: "Bank draft voided successfully."
  rescue VoidDraftService::VoidDraftError, ReversalService::ReversalError => e
    redirect_to bank_draft_path(@bank_draft), alert: e.message
  rescue ReversalService::OverrideRequiredError
    redirect_to bank_draft_path(@bank_draft), alert: "Reversal requires supervisor approval. Request an override first."
  end

  def clear
    DraftClearingService.clear!(
      bank_draft: @bank_draft,
      clearing_reference: params[:clearing_reference],
      cleared_by_id: current_user&.id
    )
    redirect_to bank_draft_path(@bank_draft), notice: "Bank draft marked cleared successfully."
  rescue DraftClearingService::DraftClearingError => e
    redirect_to bank_draft_path(@bank_draft), alert: e.message
  end

  def new
    @bank_draft_params = {}
  end

  def create
    result = DraftIssuanceService.post!(
      instrument_type: params[:instrument_type],
      remitter_party_id: params[:remitter_party_id],
      account_id: params[:account_id],
      amount_cents: (params[:amount].to_d * 100).to_i,
      payee_name: params[:payee_name],
      branch_id: params[:branch_id],
      memo: params[:memo].presence,
      expires_at: params[:expires_at].presence&.then { |d| Date.parse(d) rescue nil },
      created_by_id: current_user&.id
    )

    draft = BankDraft.find_by(posting_batch_id: result.id)
    redirect_to bank_draft_path(draft), notice: "Bank draft issued successfully."
  rescue DraftIssuanceService::DraftIssuanceError => e
    flash.now[:alert] = e.message
    @bank_draft_params = params.slice(:instrument_type, :remitter_party_id, :account_id, :amount, :payee_name, :branch_id, :memo, :expires_at)
    set_form_options
    render :new, status: :unprocessable_entity
  rescue StandardError => e
    flash.now[:alert] = "Issuance failed: #{e.message}"
    @bank_draft_params = params.slice(:instrument_type, :remitter_party_id, :account_id, :amount, :payee_name, :branch_id, :memo, :expires_at)
    set_form_options
    render :new, status: :unprocessable_entity
  end

  private

  def set_bank_draft
    @bank_draft = BankDraft
      .includes(:branch, :remitter_party, :account, :issued_by)
      .find(params[:id])
  end

  def set_form_options
    @branches = Branch.where(status: Bankcore::Enums::STATUS_ACTIVE).order(:branch_code)
    @parties = Party.where(status: Bankcore::Enums::STATUS_ACTIVE).order(:display_name)
    @accounts = Account
      .where(status: Bankcore::Enums::STATUS_ACTIVE)
      .includes(:branch, :account_balances, account_owners: :party)
      .order(:account_number)
  end
end
