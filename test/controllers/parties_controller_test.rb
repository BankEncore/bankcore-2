# frozen_string_literal: true

require "test_helper"

class PartiesControllerTest < ActionDispatch::IntegrationTest
  test "show renders customer workspace with linked account actions" do
    accounts(:one).account_balances.create!(
      posted_balance_cents: 10_000,
      available_balance_cents: 9_500,
      average_balance_cents: 8_000,
      as_of_at: Time.current
    )

    get party_url(parties(:one))

    assert_response :success
    assert_select "h1", text: /Customer Workspace/
    assert_select "a[href='#{new_account_path(party_id: parties(:one).id)}']", text: "Open New Account"
    assert_select "a[href='#{account_path(accounts(:one))}']", text: "Open"
    assert_select "a[href='#{new_transaction_path(account_id: accounts(:one).id)}']", text: "Post"
  end

  test "create redirects back into account opening when return_to is supplied" do
    assert_difference "Party.count", 1 do
      post parties_url, params: {
        return_to: new_account_path,
        party: {
          party_number: "P002",
          display_name: "Second Customer",
          party_type: "person",
          primary_branch_id: branches(:one).id
        }
      }
    end

    assert_redirected_to new_account_path(party_id: Party.last.id)
    follow_redirect!
    assert_match /continue the account opening workflow/i, flash[:notice]
    assert_select "input[name='account[primary_party_id]'][value='#{Party.last.id}']"
  end
end
