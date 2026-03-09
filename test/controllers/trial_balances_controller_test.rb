# frozen_string_literal: true

require "test_helper"

class TrialBalancesControllerTest < ActionDispatch::IntegrationTest
  setup do
    post login_url, params: { username: "testuser", password: "secret" }
  end

  test "index renders trial balance summary and drilldown links" do
    PostingEngine.post!(
      transaction_code: "ADJ_CREDIT",
      account_id: accounts(:one).id,
      amount_cents: 1_500,
      business_date: business_dates(:one).business_date,
      reference_number: "TB-CONTROLLER-1"
    )

    get trial_balances_url

    assert_response :success
    assert_select "h1", text: /Trial Balance/
    assert_select "td", text: "5190"
    assert_select "a[href='#{trial_balance_path(GlAccount.find_by!(gl_number: "5190"), business_date: business_dates(:one).business_date, include_zero: 1)}']"
  end

  test "index hides zero rows when include_zero is disabled" do
    get trial_balances_url, params: { business_date: business_dates(:one).business_date, include_zero: "0" }

    assert_response :success
    assert_select "p", text: /No trial balance rows/
  end

  test "show renders drilldown register with transaction links" do
    batch = PostingEngine.post!(
      transaction_code: "ADJ_CREDIT",
      account_id: accounts(:one).id,
      amount_cents: 2_100,
      business_date: business_dates(:one).business_date,
      reference_number: "TB-CONTROLLER-2"
    )
    gl_account = GlAccount.find_by!(gl_number: "5190")

    get trial_balance_url(gl_account), params: { business_date: business_dates(:one).business_date }

    assert_response :success
    assert_select "h1", text: /G\/L Drilldown/
    assert_select "td", text: batch.posting_reference
    assert_select "a[href='#{transaction_path(batch.operational_transaction_id)}']"
  end
end
