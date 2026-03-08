# frozen_string_literal: true

module Bankcore
  module Constants
    TRANSACTION_CODES = %w[
      ADJ_CREDIT
      ADJ_DEBIT
      XFER_INTERNAL
      FEE_POST
      INT_ACCRUAL
      INT_POST
      ACH_CREDIT
      ACH_DEBIT
    ].freeze

    REVERSAL_CODES = {
      "ADJ_CREDIT" => "ADJ_DEBIT",
      "ADJ_DEBIT" => "ADJ_CREDIT",
      "XFER_INTERNAL" => "XFER_INTERNAL",
      "FEE_POST" => "FEE_REVERSAL",
      "INT_ACCRUAL" => "INT_ACCRUAL_REVERSAL",
      "INT_POST" => "INT_POST_REVERSAL",
      "ACH_CREDIT" => "ACH_DEBIT",
      "ACH_DEBIT" => "ACH_CREDIT"
    }.freeze

    ACCOUNT_TYPES = %w[dda now savings cd loan].freeze
    DEFAULT_CURRENCY = "USD"
    # Reversals above this amount (cents) require an approved override
    REVERSAL_OVERRIDE_THRESHOLD_CENTS = (ENV["REVERSAL_OVERRIDE_THRESHOLD_CENTS"] || 10_000).to_i
  end

  TRANSACTION_CODES = Constants::TRANSACTION_CODES
  REVERSAL_OVERRIDE_THRESHOLD_CENTS = Constants::REVERSAL_OVERRIDE_THRESHOLD_CENTS
  REVERSAL_CODES = Constants::REVERSAL_CODES
  ACCOUNT_TYPES = Constants::ACCOUNT_TYPES
  DEFAULT_CURRENCY = Constants::DEFAULT_CURRENCY
end
