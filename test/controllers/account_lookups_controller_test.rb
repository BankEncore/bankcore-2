# frozen_string_literal: true

require "test_helper"

class AccountLookupsControllerTest < ActionDispatch::IntegrationTest
  test "index returns matching active accounts for post_transactions users" do
    post login_url, params: { username: "testuser", password: "secret" }

    get account_lookups_url, params: { q: "1001" }, as: :json

    assert_response :success
    payload = JSON.parse(response.body)
    assert_equal [accounts(:one).id], payload.fetch("accounts").map { |account| account.fetch("id") }
    assert_equal "DDA-1001", payload.fetch("accounts").first.fetch("account_reference")
  end

  test "index allows teller-role users because they can post transactions" do
    post login_url, params: { username: "limiteduser", password: "secret" }

    get account_lookups_url, params: { q: "DDA" }, as: :json

    assert_response :success
  end

  test "index excludes inactive accounts" do
    post login_url, params: { username: "testuser", password: "secret" }

    inactive_account = Account.create!(
      account_number: "8888",
      account_reference: "DORM-8888",
      account_type: "dda",
      branch: branches(:one),
      currency_code: "USD",
      status: "inactive"
    )

    get account_lookups_url, params: { q: inactive_account.account_reference }, as: :json

    assert_response :success
    payload = JSON.parse(response.body)
    assert_empty payload.fetch("accounts")
  end

  test "index forbids users without post_transactions permission" do
    get account_lookups_url, params: { q: "1001" }, as: :json

    assert_response :forbidden
  end
end
