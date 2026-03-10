# frozen_string_literal: true

module TransactionEntry
  class Error < StandardError; end
  class ValidationError < Error; end
  class UnsupportedTransactionError < Error; end

  class CheckOverdraftOverrideRequiredError < Error
    attr_reader :account_id, :amount_cents, :check_number

    def initialize(message = "Check overdraft above threshold requires supervisor approval.", account_id: nil, amount_cents: nil, check_number: nil)
      super(message)
      @account_id = account_id
      @amount_cents = amount_cents
      @check_number = check_number
    end
  end
end
