# frozen_string_literal: true

require "test_helper"

class OverrideRequestsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      username: "overrideuser",
      display_name: "Override User",
      status: "active",
      password: "secret",
      password_confirmation: "secret"
    )
    post login_url, params: { username: "overrideuser", password: "secret" }

    @transaction = BankingTransaction.create!(
      transaction_type: "ADJ_CREDIT",
      branch: branches(:one),
      status: "posted",
      business_date: business_dates(:one).business_date
    )
  end

  test "index renders" do
    get override_requests_url
    assert_response :success
  end

  test "new renders form with transaction context" do
    get new_override_request_url(transaction_id: @transaction.id, request_type: "reversal")
    assert_response :success
    assert_select "form[action=?]", override_requests_path
    assert_select "textarea[name=reason_text]"
  end

  test "create submits override request" do
    assert_difference "OverrideRequest.count", 1 do
      post override_requests_url, params: {
        transaction_id: @transaction.id,
        request_type: "reversal",
        operational_transaction_id: @transaction.id,
        branch_id: @transaction.branch_id,
        reason_text: "Correcting data entry error"
      }
    end
    assert_redirected_to override_request_path(OverrideRequest.last)
    assert_match /submitted/i, flash[:notice]
  end
end
