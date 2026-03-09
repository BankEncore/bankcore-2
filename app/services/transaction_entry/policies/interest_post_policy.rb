# frozen_string_literal: true

module TransactionEntry
  module Policies
    class InterestPostPolicy < BasePolicy
      def validate!
        super
        account = active_account!(request.account_id)
        raise ValidationError, "Selected account is not interest-bearing" unless account.deposit_account&.interest_bearing?
        require_field!(:posting_cycle, "Posting cycle is required for interest posting")
        validate_positive_amount!
        active_interest_rule!(account)
        self
      end
    end
  end
end
