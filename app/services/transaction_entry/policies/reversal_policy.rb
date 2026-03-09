# frozen_string_literal: true

module TransactionEntry
  module Policies
    class ReversalPolicy < BasePolicy
      def validate!
        super
        require_field!(:reversal_target_transaction_id, "Original transaction is required for reversals")
        self
      end
    end
  end
end
