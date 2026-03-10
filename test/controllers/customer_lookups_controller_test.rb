# frozen_string_literal: true

require "test_helper"

class CustomerLookupsControllerTest < ActionDispatch::IntegrationTest
  test "show renders search page" do
    get customer_lookup_url

    assert_response :success
    assert_select "h1", text: /Customer Lookup/
    assert_select "input[name='q']"
  end

  test "show returns grouped results for matching customer and account query" do
    accounts(:one).update!(account_reference: "TEST-1001")
    accounts(:one).account_balances.create!(
      posted_balance_cents: 10_000,
      available_balance_cents: 9_500,
      average_balance_cents: 8_000,
      as_of_at: Time.current
    )

    get customer_lookup_url, params: { q: "Test" }

    assert_response :success
    assert_select "h2", text: "Customers"
    assert_select "h2", text: "Accounts"
    assert_select "td", text: /Test Customer/
    assert_select "td", text: /1001/
    assert_select "a[href='#{party_path(parties(:one))}']", text: "Open"
    assert_select "a[href='#{account_path(accounts(:one))}']", text: "Open"
  end
end
