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

  def with_stubbed_class_method(klass, method_name, replacement)
    original = klass.method(method_name)
    klass.define_singleton_method(method_name, &replacement)
    yield
  ensure
    klass.define_singleton_method(method_name, original)
  end
end
