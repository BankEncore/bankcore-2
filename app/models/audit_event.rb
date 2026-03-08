# frozen_string_literal: true

class AuditEvent < ApplicationRecord
  # Polymorphic: actor and target can be various types
  # event_type: posting_succeeded, posting_failed, reversal_created, fee_assessed, interest_accrued, etc.
  # metadata_json: JSON string for additional context

  validates :event_type, presence: true
  validates :action, presence: true
end
