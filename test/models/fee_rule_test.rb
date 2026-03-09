# frozen_string_literal: true

require "test_helper"

class FeeRuleTest < ActiveSupport::TestCase
  test "uses fee type defaults when rule amount or gl override are blank" do
    fee_rule = FeeRule.new(
      fee_type: fee_types(:maintenance),
      account_product: account_products(:dda),
      priority: 100,
      method: FeeRule::METHOD_FIXED_AMOUNT
    )

    assert_equal 1500, fee_rule.amount_cents_for_assessment
    assert_equal fee_types(:maintenance).gl_account_id, fee_rule.gl_account_id_for_posting
  end

  test "validates active range ordering" do
    fee_rule = FeeRule.new(
      fee_type: fee_types(:maintenance),
      account_product: account_products(:dda),
      priority: 100,
      method: FeeRule::METHOD_FIXED_AMOUNT,
      effective_on: Date.new(2026, 3, 31),
      ends_on: Date.new(2026, 3, 1)
    )

    assert_not fee_rule.valid?
    assert_includes fee_rule.errors[:ends_on], "must be on or after effective_on"
  end
end
