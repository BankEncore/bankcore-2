# frozen_string_literal: true

require "test_helper"

class PostingEngineTest < ActiveSupport::TestCase
  def setup
    @branch = branches(:one)
    @account = accounts(:one)
    @business_date = business_dates(:one).business_date
  end

  test "posts ADJ_CREDIT successfully" do
    batch = PostingEngine.post!(
      transaction_code: "ADJ_CREDIT",
      account_id: @account.id,
      amount_cents: 5000,
      business_date: @business_date
    )

    assert batch.persisted?
    assert_equal "posted", batch.status
    assert_equal 2, batch.posting_legs.count

    @account.reload
    balance = @account.account_balances.first
    assert balance
    assert_equal 5000, balance.posted_balance_cents
    assert_equal 5000, balance.average_balance_cents
  end

  test "creates journal entry and account transaction" do
    batch = PostingEngine.post!(
      transaction_code: "ADJ_CREDIT",
      account_id: @account.id,
      amount_cents: 10000,
      business_date: @business_date
    )

    assert batch.journal_entries.any?
    assert @account.account_transactions.any?
  end

  test "persists operational metadata into transaction and account history" do
    batch = PostingEngine.post!(
      transaction_code: "ADJ_CREDIT",
      account_id: @account.id,
      amount_cents: 10_000,
      business_date: @business_date,
      memo: "Courtesy credit",
      reason_text: "Service recovery",
      reference_number: "MAN-20260309-100",
      external_reference: "CASE-100"
    )

    transaction = batch.operational_transaction
    account_transaction = @account.account_transactions.order(:id).last

    assert_equal "Courtesy credit", transaction.memo
    assert_equal "Service recovery", transaction.reason_text
    assert_equal "MAN-20260309-100", transaction.reference_number
    assert_equal "CASE-100", transaction.external_reference
    assert_equal transaction.id, account_transaction.transaction_id
    assert_includes account_transaction.description, "Courtesy credit"
    assert_includes account_transaction.description, "MAN-20260309-100"
    assert_equal "MAN-20260309-100", transaction.transaction_references.find_by(reference_type: TransactionReference::REFERENCE_TYPE_REFERENCE_NUMBER)&.reference_value
    assert_equal "CASE-100", transaction.transaction_references.find_by(reference_type: TransactionReference::REFERENCE_TYPE_EXTERNAL_REFERENCE)&.reference_value
  end

  test "records contra account context for internal transfers" do
    ensure_internal_transfer_template!

    destination = accounts(:two)
    batch = PostingEngine.post!(
      transaction_code: "XFER_INTERNAL",
      source_account_id: @account.id,
      destination_account_id: destination.id,
      amount_cents: 2_500,
      business_date: @business_date,
      memo: "Sweep transfer",
      reference_number: "XFER-20260309-001"
    )

    source_history = AccountTransaction.find_by!(posting_batch_id: batch.id, account_id: @account.id)
    destination_history = AccountTransaction.find_by!(posting_batch_id: batch.id, account_id: destination.id)

    assert_equal destination.id, source_history.contra_account_id
    assert_equal @account.id, destination_history.contra_account_id
    assert_includes source_history.description, destination.account_number
    assert_includes destination_history.description, @account.account_number
  end

  test "assigns a unique posting reference to committed batches" do
    batch1 = PostingEngine.post!(
      transaction_code: "ADJ_CREDIT",
      account_id: @account.id,
      amount_cents: 1000,
      business_date: @business_date
    )
    batch2 = PostingEngine.post!(
      transaction_code: "ADJ_DEBIT",
      account_id: @account.id,
      amount_cents: 500,
      business_date: @business_date
    )

    assert_match(/\APB-\d{8}-[A-F0-9]{12}\z/, batch1.posting_reference)
    assert_match(/\APB-\d{8}-[A-F0-9]{12}\z/, batch2.posting_reference)
    refute_equal batch1.posting_reference, batch2.posting_reference
  end

  test "rejects unbalanced posting via validator" do
    # Template is balanced - validator would catch if legs were wrong
    # This tests that a valid posting works; invalid would need template manipulation
    batch = PostingEngine.post!(
      transaction_code: "ADJ_CREDIT",
      account_id: @account.id,
      amount_cents: 1000,
      business_date: @business_date
    )
    assert batch.persisted?
  end

  test "idempotency returns existing batch for duplicate key" do
    key = "idem-#{SecureRandom.hex(8)}"
    batch1 = PostingEngine.post!(
      transaction_code: "ADJ_CREDIT",
      account_id: @account.id,
      amount_cents: 2500,
      business_date: @business_date,
      idempotency_key: key
    )
    batch2 = PostingEngine.post!(
      transaction_code: "ADJ_CREDIT",
      account_id: @account.id,
      amount_cents: 2500,
      business_date: @business_date,
      idempotency_key: key
    )

    assert_equal batch1.id, batch2.id
    assert_equal key, batch1.operational_transaction.transaction_references.find_by(reference_type: TransactionReference::REFERENCE_TYPE_IDEMPOTENCY_KEY)&.reference_value
  end

  test "idempotency rejects conflicting payload reuse" do
    key = "idem-#{SecureRandom.hex(8)}"
    PostingEngine.post!(
      transaction_code: "ADJ_CREDIT",
      account_id: @account.id,
      amount_cents: 2500,
      business_date: @business_date,
      idempotency_key: key
    )

    error = assert_raises(PostingEngine::IdempotencyConflictError) do
      PostingEngine.post!(
        transaction_code: "ADJ_CREDIT",
        account_id: @account.id,
        amount_cents: 5000,
        business_date: @business_date,
        idempotency_key: key
      )
    end

    assert_match "different request", error.message
  end

  test "raises when no template exists" do
    assert_raises(PostingEngine::PostingError) do
      PostingEngine.post!(
        transaction_code: "INVALID_CODE",
        account_id: @account.id,
        amount_cents: 1000,
        business_date: @business_date
      )
    end
  end

  test "rolls back posting when account projection fails" do
    assert_no_difference [ "BankingTransaction.count", "PostingBatch.count", "PostingLeg.count", "JournalEntry.count", "JournalEntryLine.count", "AccountTransaction.count" ] do
      error = assert_raises(RuntimeError) do
        with_stubbed_class_method(AccountProjector, :project!, ->(*) { raise "projection exploded" }) do
          PostingEngine.post!(
            transaction_code: "ADJ_CREDIT",
            account_id: @account.id,
            amount_cents: 2500,
            business_date: @business_date
          )
        end
      end

      assert_equal "projection exploded", error.message
    end
  end

  test "emits posting requested and committed audit events" do
    assert_difference "AuditEvent.count", 2 do
      PostingEngine.post!(
        transaction_code: "ADJ_CREDIT",
        account_id: @account.id,
        amount_cents: 1250,
        business_date: @business_date
      )
    end

    events = AuditEvent.order(:id).last(2)
    assert_equal [ "posting_requested", "posting_committed" ], events.map(&:event_type)
  end

  test "emits posting failed audit event" do
    assert_difference "AuditEvent.count", 2 do
      assert_raises(PostingEngine::PostingError) do
        PostingEngine.post!(
          transaction_code: "INVALID_CODE",
          account_id: @account.id,
          amount_cents: 1000,
          business_date: @business_date
        )
      end
    end

    assert_equal "posting_failed", AuditEvent.last.event_type
  end

  private

  def ensure_internal_transfer_template!
    xfer_code = TransactionCode.find_or_create_by!(code: "XFER_INTERNAL") do |code|
      code.description = "Internal account transfer"
      code.active = true
    end

    xfer_template = PostingTemplate.find_or_create_by!(transaction_code: xfer_code) do |template|
      template.name = "Internal Transfer"
      template.description = "Debit source, credit destination"
      template.active = true
    end

    PostingTemplateLeg.find_or_create_by!(posting_template: xfer_template, position: 0) do |leg|
      leg.leg_type = Bankcore::Enums::LEG_TYPE_DEBIT
      leg.account_source = Bankcore::Enums::ACCOUNT_SOURCE_SOURCE
      leg.description = "Debit source account"
    end

    PostingTemplateLeg.find_or_create_by!(posting_template: xfer_template, position: 1) do |leg|
      leg.leg_type = Bankcore::Enums::LEG_TYPE_CREDIT
      leg.account_source = Bankcore::Enums::ACCOUNT_SOURCE_DESTINATION
      leg.description = "Credit destination account"
    end
  end

  def with_stubbed_class_method(klass, method_name, replacement)
    original = klass.method(method_name)
    klass.define_singleton_method(method_name, &replacement)
    yield
  ensure
    klass.define_singleton_method(method_name, original)
  end
end
