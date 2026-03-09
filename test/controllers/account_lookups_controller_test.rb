# frozen_string_literal: true

require "test_helper"

class AccountLookupsControllerTest < ActionDispatch::IntegrationTest
  test "index returns matching active accounts for post_transactions users" do
    post login_url, params: { username: "testuser", password: "secret" }
    upsert_balance(accounts(:one), posted_balance_cents: 10_000, available_balance_cents: 9_500, average_balance_cents: 8_000)

    get account_lookups_url, params: { q: "1001" }, as: :json

    assert_response :success
    payload = JSON.parse(response.body)
    assert_equal [ accounts(:one).id ], payload.fetch("accounts").map { |account| account.fetch("id") }
    account_payload = payload.fetch("accounts").first
    assert_equal "DDA-1001", account_payload.fetch("account_reference")
    assert_equal "Test Customer", account_payload.fetch("primary_owner_name")
    assert_equal "Noninterest-Bearing DDA", account_payload.fetch("product_name")
    assert_equal "$100.00", account_payload.fetch("posted_balance_display")
    assert_equal "$95.00", account_payload.fetch("available_balance_display")
    assert_equal "MAIN", account_payload.fetch("branch_code")
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

  private

  def upsert_balance(account, posted_balance_cents:, available_balance_cents:, average_balance_cents:)
    balance = AccountBalance.find_or_initialize_by(account: account)
    balance.update!(
      posted_balance_cents: posted_balance_cents,
      available_balance_cents: available_balance_cents,
      average_balance_cents: average_balance_cents,
      as_of_at: Time.current
    )
  end
end
