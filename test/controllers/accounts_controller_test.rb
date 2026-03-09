# frozen_string_literal: true

require "test_helper"

class AccountsControllerTest < ActionDispatch::IntegrationTest
  test "index renders" do
    get accounts_url
    assert_response :success
    assert_select "h1", text: /Accounts/
    assert_select "a", text: "New Account"
  end

  test "new renders form" do
    get new_account_url
    assert_response :success
    assert_select "form"
    assert_select "input[name='account[account_number]']"
    assert_select "input[name='account[account_reference]']"
    assert_select "select[name='account[account_product_id]']"
    assert_select "select[name='account[branch_id]']"
    assert_select "input[name='account[currency_code]']", count: 0
  end

  test "create creates account with product-driven deposit defaults and redirects" do
    branch = branches(:one)
    product = account_products(:dda)
    assert_difference "Account.count", 1 do
      post accounts_url, params: {
        account: {
          account_number: "2001",
          account_reference: "CHK-2001",
          account_product_id: product.id,
          branch_id: branch.id
        }
      }
    end
    assert_redirected_to account_path(Account.last)
    account = Account.last
    assert_equal "2001", account.account_number
    assert_equal "CHK-2001", account.account_reference
    assert_equal product.id, account.account_product_id
    assert_equal "dda", account.account_type
    assert_equal "USD", account.currency_code
    assert_equal branch.id, account.branch_id
    assert_equal "dda", account.deposit_account.deposit_type
    assert_equal false, account.deposit_account.interest_bearing
    assert_equal "allow", account.deposit_account.overdraft_policy
  end

  test "create uses product defaults for interest-bearing deposit products" do
    branch = branches(:one)
    product = account_products(:now)

    assert_difference "Account.count", 1 do
      post accounts_url, params: {
        account: {
          account_number: "2003",
          account_product_id: product.id,
          branch_id: branch.id
        }
      }
    end

    account = Account.last
    assert_equal "2003", account.account_reference
    assert_equal "now", account.deposit_account.deposit_type
    assert_equal true, account.deposit_account.interest_bearing
    assert_equal "allow", account.deposit_account.overdraft_policy
  end

  test "create with primary party creates account owner" do
    branch = branches(:one)
    party = parties(:one)
    product = account_products(:dda)
    assert_difference [ "Account.count", "AccountOwner.count" ], 1 do
      post accounts_url, params: {
        account: {
          account_number: "2002",
          account_reference: "CHK-2002",
          account_product_id: product.id,
          branch_id: branch.id,
          primary_party_id: party.id
        }
      }
    end
    account = Account.last
    assert_equal 1, account.account_owners.count
    assert_equal party.id, account.account_owners.first.party_id
  end

  test "show renders account reference" do
    get account_url(accounts(:one))

    assert_response :success
    assert_select "h2", text: /Account/
    assert_select ".ui-kv-label", text: "Account Reference"
    assert_select ".ui-kv-value", text: /DDA-1001/
  end

  test "create with duplicate account number re-renders form" do
    branch = branches(:one)
    product = account_products(:dda)
    post accounts_url, params: {
      account: {
        account_number: "1001",
        account_product_id: product.id,
        branch_id: branch.id
      }
    }
    assert_response :unprocessable_entity
    assert_select "form"
    assert_select ".alert-error"
  end
end
