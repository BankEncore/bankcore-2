# frozen_string_literal: true

module TransactionEntry
  module Policies
    class InterestAccrualPolicy < BasePolicy
      def validate!
        super
        account = active_account!(request.account_id)
        raise ValidationError, "Selected account is not interest-bearing" unless account.deposit_account&.interest_bearing?
        require_field!(:accrual_date, "Accrual date is required for interest accrual")
        raise ValidationError, "Interest accrual amount must be non-negative" if request.amount_cents.present? && request.amount_cents.negative?

        active_interest_rule!(account)
        self
      end
    end
  end
end
