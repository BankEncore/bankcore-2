# frozen_string_literal: true

require "test_helper"

class OverrideRequestServiceTest < ActiveSupport::TestCase
  setup do
    @branch = Branch.first || Branch.create!(branch_code: "T", name: "Test", status: "active")
    @user = User.create!(username: "req", display_name: "Requester", status: "active", password: "password", password_confirmation: "password")
    @approver = User.create!(username: "appr", display_name: "Approver", status: "active", password: "password", password_confirmation: "password")
  end

  test "request! creates pending override" do
    req = nil
    assert_difference "AuditEvent.count", 1 do
      req = OverrideRequestService.request!(
        request_type: "reversal",
        requested_by_id: @user.id,
        branch_id: @branch.id,
        reason_text: "Correcting error"
      )
    end

    assert req.persisted?
    assert_equal "pending", req.status
    assert_equal "reversal", req.request_type
    assert_equal @user.id, req.requested_by_id
    assert_equal "override_requested", AuditEvent.last.event_type
  end

  test "approve! updates status" do
    req = OverrideRequestService.request!(
      request_type: "reversal",
      requested_by_id: @user.id,
      branch_id: @branch.id
    )

    assert_difference "AuditEvent.count", 1 do
      OverrideRequestService.approve!(override_request: req, approved_by_id: @approver.id)
    end

    req.reload
    assert_equal "approved", req.status
    assert_equal @approver.id, req.approved_by_id
    assert_equal "override_approved", AuditEvent.last.event_type
  end

  test "deny! updates status" do
    req = OverrideRequestService.request!(
      request_type: "reversal",
      requested_by_id: @user.id,
      branch_id: @branch.id
    )

    assert_difference "AuditEvent.count", 1 do
      OverrideRequestService.deny!(override_request: req, approved_by_id: @approver.id)
    end

    req.reload
    assert_equal "denied", req.status
    assert_equal "override_denied", AuditEvent.last.event_type
  end

  test "use! marks override as used" do
    req = OverrideRequestService.request!(
      request_type: "reversal",
      requested_by_id: @user.id,
      branch_id: @branch.id
    )
    OverrideRequestService.approve!(override_request: req, approved_by_id: @approver.id)

    assert_difference "AuditEvent.count", 1 do
      OverrideRequestService.use!(override_request: req)
    end

    req.reload
    assert_equal "used", req.status
    assert req.used_at.present?
    assert_equal "override_used", AuditEvent.last.event_type
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
