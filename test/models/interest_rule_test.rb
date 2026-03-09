# frozen_string_literal: true

require "test_helper"

class InterestRuleTest < ActiveSupport::TestCase
  test "active_on returns rules effective for the given date" do
    active_rules = InterestRule.active_on(Date.new(2026, 3, 7))

    assert_includes active_rules, interest_rules(:now_default)
    assert_includes active_rules, interest_rules(:savings_default)
  end

  test "validates active range ordering" do
    interest_rule = InterestRule.new(
      account_product: account_products(:savings),
      rate: 0.025,
      day_count_method: InterestRule::DAY_COUNT_METHOD_ACTUAL_365,
      posting_cadence: InterestRule::POSTING_CADENCE_MONTHLY,
      effective_on: Date.new(2026, 3, 31),
      ends_on: Date.new(2026, 3, 1)
    )

    assert_not interest_rule.valid?
    assert_includes interest_rule.errors[:ends_on], "must be on or after effective_on"
  end
end
