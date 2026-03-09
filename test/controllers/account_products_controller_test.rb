# frozen_string_literal: true

require "test_helper"

class AccountProductsControllerTest < ActionDispatch::IntegrationTest
  test "index renders" do
    get account_products_url

    assert_response :success
    assert_select "h1", text: /Account Products/
    assert_select "a", text: "New Product"
  end

  test "show renders product configuration" do
    get account_product_url(account_products(:savings))

    assert_response :success
    assert_select "h1", text: /Product Configuration/
    assert_select "a", text: "New Fee Rule"
    assert_select "a", text: "New Interest Rule"
  end

  test "create creates account product and redirects" do
    assert_difference "AccountProduct.count", 1 do
      post account_products_url, params: {
        account_product: {
          product_code: "checking_plus",
          name: "Checking Plus",
          product_family: "deposit",
          currency_code: "USD",
          statement_cycle: "monthly",
          allow_overdraft: true,
          liability_gl_account_id: gl_accounts(:six).id,
          status: Bankcore::Enums::STATUS_ACTIVE
        }
      }
    end

    account_product = AccountProduct.order(:id).last
    assert_redirected_to account_product_path(account_product)
    assert_equal "checking_plus", account_product.product_code
    assert_equal gl_accounts(:six).id, account_product.liability_gl_account_id
  end

  test "update modifies account product and redirects" do
    patch account_product_url(account_products(:dda)), params: {
      account_product: {
        name: "Updated DDA",
        product_family: "deposit",
        currency_code: "USD",
        statement_cycle: "quarterly",
        allow_overdraft: false,
        liability_gl_account_id: gl_accounts(:six).id,
        asset_gl_account_id: "",
        interest_expense_gl_account_id: "",
        status: Bankcore::Enums::STATUS_ACTIVE
      }
    }

    assert_redirected_to account_product_path(account_products(:dda))
    assert_equal "Updated DDA", account_products(:dda).reload.name
    assert_equal "quarterly", account_products(:dda).statement_cycle
  end
end
