# frozen_string_literal: true

module TransactionEntry
  class Error < StandardError; end
  class ValidationError < Error; end
  class UnsupportedTransactionError < Error; end
end
