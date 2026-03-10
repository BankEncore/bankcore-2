# frozen_string_literal: true

class OverrideRequestsController < ApplicationController
  include Bankcore::Enums

  before_action :set_override_request, only: %i[show approve deny]
  before_action -> { require_permission(:approve_overrides) }, only: %i[approve deny]

  def index
    @override_requests = OverrideRequest
      .includes(:requested_by, :approved_by, :operational_transaction, :branch)
      .order(created_at: :desc)
      .limit(100)
  end

  def show
    @transaction = @override_request.operational_transaction
    @posting_batch = @transaction&.posting_batch
  end

  def new
    @transaction = BankingTransaction.find(params[:transaction_id]) if params[:transaction_id].present?
    @check_overdraft_context = check_overdraft_context_from_params if params[:request_type] == OVERRIDE_TYPE_CHECK_OVERDRAFT
    @override_request = OverrideRequest.new(
      request_type: params[:request_type].presence || OVERRIDE_TYPE_REVERSAL,
      operational_transaction_id: @transaction&.id,
      branch_id: override_branch_id
    )
  end

  def create
    @transaction = BankingTransaction.find(params[:transaction_id]) if params[:transaction_id].present?
    context_json = context_json_for_request
    req = OverrideRequestService.request!(
      request_type: params[:request_type].presence || OVERRIDE_TYPE_REVERSAL,
      requested_by_id: current_user&.id,
      branch_id: create_branch_id,
      operational_transaction_id: params[:operational_transaction_id].presence || @transaction&.id,
      reason_text: params[:reason_text].presence,
      context_json: context_json
    )
    redirect_to override_request_path(req), notice: "Override request submitted. Awaiting supervisor approval."
  rescue OverrideRequestService::OverrideError => e
    @override_request = OverrideRequest.new(
      request_type: params[:request_type],
      reason_text: params[:reason_text]
    )
    @transaction = BankingTransaction.find_by(id: params[:operational_transaction_id])
    flash.now[:alert] = e.message
    render :new, status: :unprocessable_entity
  end

  def approve
    OverrideRequestService.approve!(override_request: @override_request, approved_by_id: current_user&.id)
    redirect_to override_request_path(@override_request), notice: "Override approved."
  rescue OverrideRequestService::OverrideError => e
    redirect_to override_request_path(@override_request), alert: "Approval failed: #{e.message}"
  end

  def deny
    OverrideRequestService.deny!(override_request: @override_request, approved_by_id: current_user&.id)
    redirect_to override_requests_path, notice: "Override denied."
  rescue OverrideRequestService::OverrideError => e
    redirect_to override_request_path(@override_request), alert: "Denial failed: #{e.message}"
  end

  private

  def set_override_request
    @override_request = OverrideRequest.find(params[:id])
  end

  def override_branch_id
    return @transaction&.branch_id if @transaction
    return nil unless params[:account_id].present?

    Account.find_by(id: params[:account_id])&.branch_id
  end

  def create_branch_id
    params[:branch_id].presence || @transaction&.branch_id || (params[:account_id].present? && Account.find_by(id: params[:account_id])&.branch_id)
  end

  def check_overdraft_context_from_params
    return nil unless params[:account_id].present? && params[:amount_cents].present? && params[:check_number].present?

    {
      account_id: params[:account_id].to_i,
      amount_cents: params[:amount_cents].to_i,
      check_number: params[:check_number].to_s.strip
    }
  end

  def context_json_for_request
    return nil unless params[:request_type] == OVERRIDE_TYPE_CHECK_OVERDRAFT

    ctx = check_overdraft_context_from_params
    ctx ? ctx.to_json : nil
  end
end
