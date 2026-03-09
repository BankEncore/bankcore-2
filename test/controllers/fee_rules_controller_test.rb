# frozen_string_literal: true

require "test_helper"

class FeeRulesControllerTest < ActionDispatch::IntegrationTest
  test "new renders fee rule form" do
    get new_account_product_fee_rule_url(account_products(:dda))

    assert_response :success
    assert_select "form"
    assert_select "select[name='fee_rule[fee_type_id]']"
    assert_select "input[name='fee_rule[priority]']"
  end

  test "create creates fee rule and redirects" do
    product = account_products(:now)

    assert_difference "FeeRule.count", 1 do
      post account_product_fee_rules_url(product), params: {
        fee_rule: {
          fee_type_id: fee_types(:maintenance).id,
          priority: 200,
          method: FeeRule::METHOD_FIXED_AMOUNT,
          amount_cents: 2500,
          gl_account_id: gl_accounts(:ten).id,
          effective_on: Date.new(2026, 4, 1)
        }
      }
    end

    fee_rule = FeeRule.order(:id).last
    assert_redirected_to account_product_path(product)
    assert_equal product.id, fee_rule.account_product_id
    assert_equal 2500, fee_rule.amount_cents
  end

  test "update modifies fee rule and redirects" do
    patch fee_rule_url(fee_rules(:maintenance_dda)), params: {
      fee_rule: {
        fee_type_id: fee_types(:maintenance).id,
        priority: 150,
        method: FeeRule::METHOD_FIXED_AMOUNT,
        amount_cents: 1750,
        gl_account_id: "",
        effective_on: Date.new(2026, 3, 1),
        ends_on: Date.new(2026, 12, 31)
      }
    }

    assert_redirected_to account_product_path(account_products(:dda))
    fee_rule = fee_rules(:maintenance_dda).reload
    assert_equal 150, fee_rule.priority
    assert_equal 1750, fee_rule.amount_cents
    assert_equal Date.new(2026, 12, 31), fee_rule.ends_on
  end
end
