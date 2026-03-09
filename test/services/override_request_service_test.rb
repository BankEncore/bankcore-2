# frozen_string_literal: true

require "test_helper"

class OverrideRequestServiceTest < ActiveSupport::TestCase
  setup do
    @branch = Branch.first || Branch.create!(branch_code: "T", name: "Test", status: "active")
    @user = User.create!(username: "req", display_name: "Requester", status: "active", password: "password", password_confirmation: "password")
    @approver = User.create!(username: "appr", display_name: "Approver", status: "active", password: "password", password_confirmation: "password")
    @transaction = BankingTransaction.create!(
      transaction_type: "ADJ_CREDIT",
      branch: @branch,
      status: Bankcore::Enums::STATUS_POSTED,
      business_date: BusinessDateService.current
    )
  end

  test "request! creates pending override" do
    req = nil
    assert_difference "TransactionException.count", 1 do
      assert_difference "AuditEvent.count", 1 do
        req = OverrideRequestService.request!(
          request_type: "reversal",
          requested_by_id: @user.id,
          branch_id: @branch.id,
          operational_transaction_id: @transaction.id,
          reason_text: "Correcting error"
        )
      end
    end

    assert req.persisted?
    assert_equal "pending", req.status
    assert_equal "reversal", req.request_type
    assert_equal @user.id, req.requested_by_id
    assert_equal "override_requested", AuditEvent.last.event_type
    transaction_exception = TransactionException.last
    assert_equal @transaction.id, transaction_exception.transaction_id
    assert_equal TransactionException::STATUS_OPEN, transaction_exception.status
  end

  test "approve! updates status" do
    TransactionException.create!(
      operational_transaction: @transaction,
      exception_type: TransactionException::EXCEPTION_TYPE_OVERRIDE_REQUIRED,
      status: TransactionException::STATUS_OPEN,
      requires_override: true,
      reason_code: "reversal_threshold"
    )
    req = OverrideRequestService.request!(
      request_type: "reversal",
      requested_by_id: @user.id,
      branch_id: @branch.id,
      operational_transaction_id: @transaction.id
    )

    assert_difference "AuditEvent.count", 1 do
      OverrideRequestService.approve!(override_request: req, approved_by_id: @approver.id)
    end

    req.reload
    assert_equal "approved", req.status
    assert_equal @approver.id, req.approved_by_id
    assert_equal "override_approved", AuditEvent.last.event_type
    transaction_exception = TransactionException.find_by!(transaction_id: @transaction.id, reason_code: "reversal_threshold")
    assert_equal TransactionException::STATUS_RESOLVED, transaction_exception.status
    assert_equal @approver.id, transaction_exception.resolved_by_id
  end

  test "deny! updates status" do
    TransactionException.create!(
      operational_transaction: @transaction,
      exception_type: TransactionException::EXCEPTION_TYPE_OVERRIDE_REQUIRED,
      status: TransactionException::STATUS_OPEN,
      requires_override: true,
      reason_code: "reversal_threshold"
    )
    req = OverrideRequestService.request!(
      request_type: "reversal",
      requested_by_id: @user.id,
      branch_id: @branch.id,
      operational_transaction_id: @transaction.id
    )

    assert_difference "AuditEvent.count", 1 do
      OverrideRequestService.deny!(override_request: req, approved_by_id: @approver.id)
    end

    req.reload
    assert_equal "denied", req.status
    assert_equal "override_denied", AuditEvent.last.event_type
    transaction_exception = TransactionException.find_by!(transaction_id: @transaction.id, reason_code: "reversal_threshold")
    assert_equal TransactionException::STATUS_BLOCKED, transaction_exception.status
    assert_equal @approver.id, transaction_exception.resolved_by_id
  end

  test "use! marks override as used" do
    req = OverrideRequestService.request!(
      request_type: "reversal",
      requested_by_id: @user.id,
      branch_id: @branch.id,
      operational_transaction_id: @transaction.id
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
      branch_id: @branch.id,
      operational_transaction_id: @transaction.id
    )
    OverrideRequestService.approve!(override_request: req, approved_by_id: @approver.id)

    assert_raises(OverrideRequestService::OverrideError) do
      OverrideRequestService.approve!(override_request: req, approved_by_id: @approver.id)
    end
  end
end
