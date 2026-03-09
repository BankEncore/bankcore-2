# frozen_string_literal: true

module TransactionEntry
  module Policies
    class AdjustmentPolicy < BasePolicy
      def validate!
        super
        active_account!(request.account_id)
        validate_positive_amount!
        require_field!(:reason_text, "Reason / justification is required for manual adjustments")
        require_field!(:reference_number, "Reference number is required for manual adjustments")
        self
      end

      def preview_context_rows
        [
          [ "Mode", request.transaction_code == "ADJ_DEBIT" ? "Manual debit adjustment" : "Manual credit adjustment" ],
          [ "Policy", request.transaction_code == "ADJ_DEBIT" ? "Debit adjustments require explicit reason and reference capture." : "Credit adjustments remain operator-governed and fully traceable." ]
        ]
      end
    end
  end
end
