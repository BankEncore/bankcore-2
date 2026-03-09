# frozen_string_literal: true

require "test_helper"

class InterestRulesControllerTest < ActionDispatch::IntegrationTest
  test "new renders interest rule form" do
    get new_account_product_interest_rule_url(account_products(:savings))

    assert_response :success
    assert_select "form"
    assert_select "input[name='interest_rule[rate]']"
    assert_select "select[name='interest_rule[posting_cadence]']"
  end

  test "create creates interest rule and redirects" do
    product = account_products(:now)

    assert_difference "InterestRule.count", 1 do
      post account_product_interest_rules_url(product), params: {
        interest_rule: {
          rate: "0.015000",
          day_count_method: InterestRule::DAY_COUNT_METHOD_ACTUAL_365,
          posting_cadence: InterestRule::POSTING_CADENCE_MONTHLY,
          effective_on: Date.new(2026, 4, 1)
        }
      }
    end

    interest_rule = InterestRule.order(:id).last
    assert_redirected_to account_product_path(product)
    assert_equal product.id, interest_rule.account_product_id
    assert_equal BigDecimal("0.015"), interest_rule.rate
  end

  test "update modifies interest rule and redirects" do
    patch interest_rule_url(interest_rules(:savings_default)), params: {
      interest_rule: {
        rate: "0.025000",
        day_count_method: InterestRule::DAY_COUNT_METHOD_30_360,
        posting_cadence: InterestRule::POSTING_CADENCE_QUARTERLY,
        effective_on: Date.new(2026, 3, 1),
        ends_on: Date.new(2026, 12, 31)
      }
    }

    assert_redirected_to account_product_path(account_products(:savings))
    interest_rule = interest_rules(:savings_default).reload
    assert_equal BigDecimal("0.025"), interest_rule.rate
    assert_equal InterestRule::DAY_COUNT_METHOD_30_360, interest_rule.day_count_method
    assert_equal InterestRule::POSTING_CADENCE_QUARTERLY, interest_rule.posting_cadence
  end
end
