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

  test "approve requires approve_overrides permission" do
    override = OverrideRequest.create!(
      request_type: "reversal",
      status: "pending",
      operational_transaction_id: @transaction.id,
      branch_id: @transaction.branch_id,
      requested_by_id: @user.id
    )

    delete logout_url
    post login_url, params: { username: "limiteduser", password: "secret" }
    post approve_override_request_url(override)

    assert_response :forbidden
    assert_match /do not have permission/i, flash[:alert]
  end

  test "approve succeeds with approve_overrides permission" do
    post login_url, params: { username: "testuser", password: "secret" }

    override = OverrideRequest.create!(
      request_type: "reversal",
      status: "pending",
      operational_transaction_id: @transaction.id,
      branch_id: @transaction.branch_id,
      requested_by_id: users(:one).id
    )

    post approve_override_request_url(override)

    assert_redirected_to override_request_path(override)
    assert_match /approved/i, flash[:notice]
    override.reload
    assert_equal "approved", override.status
  end
end
