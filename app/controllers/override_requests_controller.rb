# frozen_string_literal: true

class OverrideRequestsController < ApplicationController
  include Bankcore::Enums

  before_action :set_override_request, only: %i[show approve deny]

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
    @override_request = OverrideRequest.new(
      request_type: params[:request_type].presence || OVERRIDE_TYPE_REVERSAL,
      operational_transaction_id: @transaction&.id,
      branch_id: @transaction&.branch_id
    )
  end

  def create
    @transaction = BankingTransaction.find(params[:transaction_id]) if params[:transaction_id].present?
    req = OverrideRequestService.request!(
      request_type: params[:request_type].presence || OVERRIDE_TYPE_REVERSAL,
      requested_by_id: current_user&.id,
      branch_id: params[:branch_id].presence || @transaction&.branch_id,
      operational_transaction_id: params[:operational_transaction_id].presence || @transaction&.id,
      reason_text: params[:reason_text].presence
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
end
