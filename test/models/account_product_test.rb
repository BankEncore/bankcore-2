# frozen_string_literal: true

require "test_helper"

class AccountProductTest < ActiveSupport::TestCase
  test "validates product_code presence and uniqueness" do
    product = AccountProduct.new(
      name: "Test Product",
      product_family: "deposit",
      currency_code: "USD",
      statement_cycle: "monthly",
      allow_overdraft: false,
      status: "active"
    )
    assert_not product.valid?
    assert_includes product.errors[:product_code], "can't be blank"

    duplicate = AccountProduct.new(
      product_code: account_products(:dda).product_code,
      name: "Duplicate",
      product_family: "deposit",
      currency_code: "USD",
      statement_cycle: "monthly",
      allow_overdraft: false,
      status: "active"
    )
    assert_not duplicate.valid?
  end

  test "derives deposit defaults from product code" do
    assert_equal "dda", account_products(:dda).default_deposit_type
    assert_not account_products(:dda).default_interest_bearing?
    assert_equal "allow", account_products(:dda).default_overdraft_policy

    assert_equal "savings", account_products(:savings).default_deposit_type
    assert account_products(:savings).default_interest_bearing?
    assert_equal "disallow", account_products(:savings).default_overdraft_policy
  end

  test "resolves product-aware interest expense gls" do
    assert_equal "5120", account_products(:now).resolved_interest_expense_gl_account.gl_number
    assert_equal "5130", account_products(:savings).resolved_interest_expense_gl_account.gl_number
  end

  test "validates statement_cycle inclusion" do
    product = account_products(:dda).dup
    product.product_code = "dda_invalid_cycle"
    product.statement_cycle = "weekly"

    assert_not product.valid?
    assert_includes product.errors[:statement_cycle], "is not included in the list"
  end

  test "validates interest-bearing products require an expense gl" do
    product = account_products(:now).dup
    product.interest_expense_gl_account = nil

    assert_not product.valid?
    assert_includes product.errors[:interest_expense_gl_account], "must be present for interest-bearing products"
  end
end
