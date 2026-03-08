# frozen_string_literal: true

require "test_helper"

class OverrideRequestServiceTest < ActiveSupport::TestCase
  setup do
    @branch = Branch.first || Branch.create!(branch_code: "T", name: "Test", status: "active")
    @user = User.create!(username: "req", display_name: "Requester", status: "active", password: "password", password_confirmation: "password")
    @approver = User.create!(username: "appr", display_name: "Approver", status: "active", password: "password", password_confirmation: "password")
  end

  test "request! creates pending override" do
    req = OverrideRequestService.request!(
      request_type: "reversal",
      requested_by_id: @user.id,
      branch_id: @branch.id,
      reason_text: "Correcting error"
    )

    assert req.persisted?
    assert_equal "pending", req.status
    assert_equal "reversal", req.request_type
    assert_equal @user.id, req.requested_by_id
  end

  test "approve! updates status" do
    req = OverrideRequestService.request!(
      request_type: "reversal",
      requested_by_id: @user.id,
      branch_id: @branch.id
    )

    OverrideRequestService.approve!(override_request: req, approved_by_id: @approver.id)

    req.reload
    assert_equal "approved", req.status
    assert_equal @approver.id, req.approved_by_id
  end

  test "deny! updates status" do
    req = OverrideRequestService.request!(
      request_type: "reversal",
      requested_by_id: @user.id,
      branch_id: @branch.id
    )

    OverrideRequestService.deny!(override_request: req, approved_by_id: @approver.id)

    req.reload
    assert_equal "denied", req.status
  end

  test "use! marks override as used" do
    req = OverrideRequestService.request!(
      request_type: "reversal",
      requested_by_id: @user.id,
      branch_id: @branch.id
    )
    OverrideRequestService.approve!(override_request: req, approved_by_id: @approver.id)

    OverrideRequestService.use!(override_request: req)

    req.reload
    assert_equal "used", req.status
    assert req.used_at.present?
  end

  test "approve! raises when not pending" do
    req = OverrideRequestService.request!(
      request_type: "reversal",
      requested_by_id: @user.id,
      branch_id: @branch.id
    )
    OverrideRequestService.approve!(override_request: req, approved_by_id: @approver.id)

    assert_raises(OverrideRequestService::OverrideError) do
      OverrideRequestService.approve!(override_request: req, approved_by_id: @approver.id)
    end
  end
end
