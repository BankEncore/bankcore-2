# frozen_string_literal: true

class OverrideRequestService
  include Bankcore::Enums

  class OverrideError < StandardError; end

  def self.request!(request_type:, requested_by_id: nil, branch_id: nil, operational_transaction_id: nil,
                    reason_text: nil, expires_at: nil)
    new(
      request_type: request_type,
      requested_by_id: requested_by_id,
      branch_id: branch_id,
      operational_transaction_id: operational_transaction_id,
      reason_text: reason_text,
      expires_at: expires_at
    ).request!
  end

  def self.approve!(override_request:, approved_by_id:)
    new(override_request: override_request, approved_by_id: approved_by_id).approve!
  end

  def self.deny!(override_request:, approved_by_id:)
    new(override_request: override_request, approved_by_id: approved_by_id).deny!
  end

  def self.use!(override_request:)
    new(override_request: override_request).use!
  end

  def initialize(override_request: nil, approved_by_id: nil, request_type: nil, requested_by_id: nil,
                 branch_id: nil, operational_transaction_id: nil, reason_text: nil, expires_at: nil)
    @override_request = override_request
    @approved_by_id = approved_by_id
    @request_type = request_type
    @requested_by_id = requested_by_id
    @branch_id = branch_id
    @operational_transaction_id = operational_transaction_id
    @reason_text = reason_text
    @expires_at = expires_at
  end

  def request!
    raise OverrideError, "Invalid request type" unless OVERRIDE_TYPES.include?(@request_type)

    OverrideRequest.create!(
      request_type: @request_type,
      status: OVERRIDE_STATUS_PENDING,
      requested_by_id: @requested_by_id,
      branch_id: @branch_id,
      operational_transaction_id: @operational_transaction_id,
      reason_text: @reason_text,
      expires_at: @expires_at
    )
  end

  def approve!
    raise OverrideError, "Override is not pending" unless @override_request.status == OVERRIDE_STATUS_PENDING
    raise OverrideError, "Override has expired" if expired?(@override_request)

    @override_request.update!(
      status: OVERRIDE_STATUS_APPROVED,
      approved_by_id: @approved_by_id
    )
    @override_request
  end

  def deny!
    raise OverrideError, "Override is not pending" unless @override_request.status == OVERRIDE_STATUS_PENDING

    @override_request.update!(
      status: OVERRIDE_STATUS_DENIED,
      approved_by_id: @approved_by_id
    )
    @override_request
  end

  def use!
    raise OverrideError, "Override is not approved" unless @override_request.status == OVERRIDE_STATUS_APPROVED
    raise OverrideError, "Override already used" if @override_request.used_at.present?
    raise OverrideError, "Override has expired" if expired?(@override_request)

    @override_request.update!(status: OVERRIDE_STATUS_USED, used_at: Time.current)
    @override_request
  end

  private

  def expired?(override_request)
    override_request.expires_at.present? && override_request.expires_at < Time.current
  end
end
