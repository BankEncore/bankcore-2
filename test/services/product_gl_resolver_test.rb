# frozen_string_literal: true

require "test_helper"

class ProductGlResolverTest < ActiveSupport::TestCase
  test "resolves liability gl from account product" do
    gl_account = ProductGlResolver.resolve_account_gl(accounts(:one))

    assert_equal "2110", gl_account.gl_number
  end

  test "falls back to account_type mapping when product is absent" do
    account = Account.create!(
      account_number: "2010",
      account_type: "savings",
      branch: branches(:one),
      currency_code: "USD",
      status: "active"
    )

    gl_account = ProductGlResolver.resolve_account_gl(account)

    assert_equal "2130", gl_account.gl_number
  end
end
