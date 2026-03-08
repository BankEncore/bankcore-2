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
    assert_select "select[name='account[account_type]']"
    assert_select "select[name='account[branch_id]']"
  end

  test "create creates account and redirects" do
    branch = branches(:one)
    assert_difference "Account.count", 1 do
      post accounts_url, params: {
        account: {
          account_number: "2001",
          account_type: "dda",
          branch_id: branch.id,
          currency_code: "USD"
        }
      }
    end
    assert_redirected_to account_path(Account.last)
    account = Account.last
    assert_equal "2001", account.account_number
    assert_equal "dda", account.account_type
    assert_equal branch.id, account.branch_id
    assert_not_nil account.deposit_account
  end

  test "create with primary party creates account owner" do
    branch = branches(:one)
    party = parties(:one)
    assert_difference [ "Account.count", "AccountOwner.count" ], 1 do
      post accounts_url, params: {
        account: {
          account_number: "2002",
          account_type: "dda",
          branch_id: branch.id,
          currency_code: "USD",
          primary_party_id: party.id
        }
      }
    end
    account = Account.last
    assert_equal 1, account.account_owners.count
    assert_equal party.id, account.account_owners.first.party_id
  end

  test "create with duplicate account number re-renders form" do
    branch = branches(:one)
    post accounts_url, params: {
      account: {
        account_number: "1001",
        account_type: "dda",
        branch_id: branch.id,
        currency_code: "USD"
      }
    }
    assert_response :unprocessable_entity
    assert_select "form"
    assert_select ".alert-error"
  end
end
