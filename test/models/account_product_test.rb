# frozen_string_literal: true

require "test_helper"

class AccountProductTest < ActiveSupport::TestCase
  test "validates product_code presence and uniqueness" do
    product = AccountProduct.new(name: "Test Product", product_family: "deposit", currency_code: "USD", status: "active")
    assert_not product.valid?
    assert_includes product.errors[:product_code], "can't be blank"

    duplicate = AccountProduct.new(
      product_code: account_products(:dda).product_code,
      name: "Duplicate",
      product_family: "deposit",
      currency_code: "USD",
      status: "active"
    )
    assert_not duplicate.valid?
  end
end
