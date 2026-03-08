# frozen_string_literal: true

class AuditEventsController < ApplicationController
  def index
    @audit_events = AuditEvent
      .order(occurred_at: :desc)
      .limit(100)

    @audit_events = @audit_events.where(event_type: params[:event_type]) if params[:event_type].present?
  end
end
