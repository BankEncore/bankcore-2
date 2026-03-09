# frozen_string_literal: true

module TransactionEntry
  module Policies
    class TransferPolicy < BasePolicy
      def validate!
        super
        source_account = active_account!(request.source_account_id)
        destination_account = active_account!(request.destination_account_id)
        validate_positive_amount!
        raise ValidationError, "Source and destination accounts must differ" if source_account.id == destination_account.id
        raise ValidationError, "Transfer accounts must use the same currency" if source_account.currency_code != destination_account.currency_code

        require_one_of!(:memo, :reference_number)
        self
      end

      def preview_context_rows
        [
          [ "Transfer Mode", "Internal account transfer" ],
          [ "Contra Context", "Preview should show both source and destination accounts before posting." ]
        ]
      end
    end
  end
end
