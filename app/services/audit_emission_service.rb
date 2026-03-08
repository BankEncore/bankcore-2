# frozen_string_literal: true

class AuditEmissionService
  include Bankcore::Enums

  EVENT_POSTING_SUCCEEDED = "posting_succeeded"
  EVENT_POSTING_FAILED = "posting_failed"
  EVENT_REVERSAL_CREATED = "reversal_created"
  EVENT_FEE_ASSESSED = "fee_assessed"
  EVENT_INTEREST_ACCRUED = "interest_accrued"
  EVENT_INTEREST_POSTED = "interest_posted"
  EVENT_BUSINESS_DATE_CLOSED = "business_date_closed"
  EVENT_BUSINESS_DATE_OPENED = "business_date_opened"

  def self.emit!(event_type:, action:, target: nil, actor: nil, business_date: nil, metadata: {})
    new(
      event_type: event_type,
      action: action,
      target: target,
      actor: actor,
      business_date: business_date,
      metadata: metadata
    ).emit!
  end

  def initialize(event_type:, action:, target: nil, actor: nil, business_date: nil, metadata: {})
    @event_type = event_type
    @action = action
    @target = target
    @actor = actor
    @business_date = business_date
    @metadata = metadata
  end

  def emit!
    AuditEvent.create!(
      event_type: @event_type,
      action: @action,
      target_type: @target&.class&.name,
      target_id: @target&.id,
      actor_type: @actor&.class&.name,
      actor_id: @actor&.id,
      business_date: @business_date,
      occurred_at: Time.current,
      status: "recorded",
      metadata_json: @metadata.presence && @metadata.to_json
    )
  end
end
