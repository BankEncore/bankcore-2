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

    override_request = OverrideRequest.create!(
      request_type: @request_type,
      status: OVERRIDE_STATUS_PENDING,
      requested_by_id: @requested_by_id,
      branch_id: @branch_id,
      operational_transaction_id: @operational_transaction_id,
      reason_text: @reason_text,
      expires_at: @expires_at
    )
    ensure_transaction_exception_open!

    AuditEmissionService.emit!(
      event_type: AuditEmissionService::EVENT_OVERRIDE_REQUESTED,
      action: "request",
      target: override_request,
      business_date: BusinessDateService.current,
      metadata: {
        request_type: override_request.request_type,
        operational_transaction_id: override_request.operational_transaction_id
      }.compact
    )
    override_request
  end

  def approve!
    raise OverrideError, "Override is not pending" unless @override_request.status == OVERRIDE_STATUS_PENDING
    raise OverrideError, "Override has expired" if expired?(@override_request)

    @override_request.update!(
      status: OVERRIDE_STATUS_APPROVED,
      approved_by_id: @approved_by_id
    )
    resolve_transaction_exceptions!(resolved_by_id: @approved_by_id)
    emit_override_event!(AuditEmissionService::EVENT_OVERRIDE_APPROVED, "approve")
    @override_request
  end

  def deny!
    raise OverrideError, "Override is not pending" unless @override_request.status == OVERRIDE_STATUS_PENDING

    @override_request.update!(
      status: OVERRIDE_STATUS_DENIED,
      approved_by_id: @approved_by_id
    )
    block_transaction_exceptions!(resolved_by_id: @approved_by_id)
    emit_override_event!(AuditEmissionService::EVENT_OVERRIDE_DENIED, "deny")
    @override_request
  end

  def use!
    raise OverrideError, "Override is not approved" unless @override_request.status == OVERRIDE_STATUS_APPROVED
    raise OverrideError, "Override already used" if @override_request.used_at.present?
    raise OverrideError, "Override has expired" if expired?(@override_request)

    @override_request.update!(status: OVERRIDE_STATUS_USED, used_at: Time.current)
    resolve_transaction_exceptions!(resolved_by_id: @override_request.approved_by_id)
    emit_override_event!(AuditEmissionService::EVENT_OVERRIDE_USED, "use")
    @override_request
  end

  private

  def ensure_transaction_exception_open!
    return unless @operational_transaction_id.present?

    TransactionException.find_or_create_by!(
      transaction_id: @operational_transaction_id,
      exception_type: exception_type_for_request(@request_type),
      status: TransactionException::STATUS_OPEN,
      reason_code: reason_code_for_request(@request_type),
      requires_override: requires_override_for_request?(@request_type)
    )
  end

  def resolve_transaction_exceptions!(resolved_by_id:)
    return unless @override_request.operational_transaction_id.present?

    matching_transaction_exceptions.find_each do |transaction_exception|
      transaction_exception.resolve!(resolved_by_id: resolved_by_id)
    end
  end

  def block_transaction_exceptions!(resolved_by_id:)
    return unless @override_request.operational_transaction_id.present?

    matching_transaction_exceptions.find_each do |transaction_exception|
      transaction_exception.block!(resolved_by_id: resolved_by_id)
    end
  end

  def emit_override_event!(event_type, action)
    AuditEmissionService.emit!(
      event_type: event_type,
      action: action,
      target: @override_request,
      business_date: BusinessDateService.current,
      metadata: {
        request_type: @override_request.request_type,
        operational_transaction_id: @override_request.operational_transaction_id
      }.compact
    )
  end

  def expired?(override_request)
    override_request.expires_at.present? && override_request.expires_at < Time.current
  end

  def matching_transaction_exceptions
    TransactionException.open.where(
      transaction_id: @override_request.operational_transaction_id,
      exception_type: exception_type_for_request(@override_request.request_type)
    )
  end

  def exception_type_for_request(request_type)
    case request_type
    when OVERRIDE_TYPE_REVERSAL then TransactionException::EXCEPTION_TYPE_OVERRIDE_REQUIRED
    else TransactionException::EXCEPTION_TYPE_POLICY_BLOCKED
    end
  end

  def reason_code_for_request(request_type)
    case request_type
    when OVERRIDE_TYPE_REVERSAL then "reversal_threshold"
    else request_type
    end
  end

  def requires_override_for_request?(request_type)
    request_type == OVERRIDE_TYPE_REVERSAL
  end
end
