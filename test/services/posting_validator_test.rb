# frozen_string_literal: true

require "test_helper"

class PostingValidatorTest < ActiveSupport::TestCase
  test "validates balanced legs" do
    legs = [
      { leg_type: "debit", ledger_scope: "gl", account_id: nil, gl_account_id: 1, amount_cents: 1000, currency_code: "USD" },
      { leg_type: "credit", ledger_scope: "account", account_id: 1, gl_account_id: nil, amount_cents: 1000, currency_code: "USD" }
    ]
    validator = PostingValidator.new(legs: legs, business_date: business_dates(:one).business_date)
    assert_nothing_raised { validator.validate! }
  end

  test "raises UnbalancedPostingError when debits != credits" do
    legs = [
      { leg_type: "debit", ledger_scope: "gl", account_id: nil, gl_account_id: 1, amount_cents: 1000, currency_code: "USD" },
      { leg_type: "credit", ledger_scope: "account", account_id: 1, gl_account_id: nil, amount_cents: 500, currency_code: "USD" }
    ]
    validator = PostingValidator.new(legs: legs, business_date: business_dates(:one).business_date)

    assert_raises(PostingValidator::UnbalancedPostingError) { validator.validate! }
  end

  test "raises InvalidAmountError when leg amount is zero or negative" do
    legs = [
      { leg_type: "debit", ledger_scope: "gl", account_id: nil, gl_account_id: 1, amount_cents: 0, currency_code: "USD" },
      { leg_type: "credit", ledger_scope: "account", account_id: 1, gl_account_id: nil, amount_cents: 0, currency_code: "USD" }
    ]
    validator = PostingValidator.new(legs: legs, business_date: business_dates(:one).business_date)

    assert_raises(PostingValidator::InvalidAmountError) { validator.validate! }
  end

  test "raises InvalidAmountError when leg amount is negative" do
    legs = [
      { leg_type: "debit", ledger_scope: "gl", account_id: nil, gl_account_id: 1, amount_cents: -100, currency_code: "USD" },
      { leg_type: "credit", ledger_scope: "account", account_id: 1, gl_account_id: nil, amount_cents: -100, currency_code: "USD" }
    ]
    validator = PostingValidator.new(legs: legs, business_date: business_dates(:one).business_date)

    assert_raises(PostingValidator::InvalidAmountError) { validator.validate! }
  end

  test "raises InvalidTargetError when account leg missing account_id" do
    legs = [
      { leg_type: "credit", ledger_scope: "account", account_id: nil, gl_account_id: nil, amount_cents: 1000, currency_code: "USD" }
    ]
    validator = PostingValidator.new(legs: legs, business_date: business_dates(:one).business_date)

    assert_raises(PostingValidator::InvalidTargetError) { validator.validate! }
  end

  test "raises BusinessDateClosedError when date not open" do
    legs = [
      { leg_type: "debit", ledger_scope: "gl", account_id: nil, gl_account_id: 1, amount_cents: 1000, currency_code: "USD" },
      { leg_type: "credit", ledger_scope: "account", account_id: 1, gl_account_id: nil, amount_cents: 1000, currency_code: "USD" }
    ]
    closed_date = Date.current + 30
    validator = PostingValidator.new(legs: legs, business_date: closed_date)

    assert_raises(PostingValidator::BusinessDateClosedError) { validator.validate! }
  end
end
