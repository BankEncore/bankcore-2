# frozen_string_literal: true

module TransactionEntry
  module Policies
    class AchPolicy < BasePolicy
      def validate!
        super
        active_account!(request.account_id)
        validate_positive_amount!
        require_field!(:ach_trace_number, "ACH trace number is required")
        require_field!(:ach_effective_date, "ACH effective date is required")
        require_field!(:ach_batch_reference, "ACH batch reference is required")
        require_field!(:authorization_reference, "Authorization reference is required for ACH debits") if request.transaction_code == "ACH_DEBIT"
        self
      end

      def preview_context_rows
        rows = [
          [ "ACH Trace", request.ach_trace_number ],
          [ "Effective Date", request.ach_effective_date&.iso8601 ],
          [ "Batch Reference", request.ach_batch_reference ]
        ]
        rows << [ "Company Name", request.ach_company_name ] if request.ach_company_name.present?
        rows << [ "Identification Number", request.ach_identification_number ] if request.ach_identification_number.present?
        rows << [ "Authorization", request.authorization_reference ] if request.authorization_reference.present?
        rows
      end

      def ach_service_attributes
        post_attributes.merge(
          ach_trace_number: request.ach_trace_number,
          ach_effective_date: request.ach_effective_date,
          ach_batch_reference: request.ach_batch_reference,
          ach_company_name: request.ach_company_name,
          ach_identification_number: request.ach_identification_number,
          authorization_reference: request.authorization_reference,
          authorization_source: request.authorization_source
        )
      end
    end
  end
end
