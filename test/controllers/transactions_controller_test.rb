# frozen_string_literal: true

require "test_helper"

class TransactionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    post login_url, params: { username: "testuser", password: "secret" }
    ensure_ach_template!
    ensure_fee_post_template!
  end

  test "index renders" do
    get transactions_url
    assert_response :success
  end

  test "new renders form" do
    get new_transaction_url
    assert_response :success
    assert_select "select#transaction_code"
    assert_select "input#account_id[type='hidden']"
    assert_select "input#account_id_lookup[type='search']"
    assert_select "input[name='transaction[amount]']"
    assert_select "select[name='transaction[fee_type_id]']"
    assert_select "input[name='transaction[ach_trace_number]']"
    assert_select "a[href='#{interest_accruals_path}']"
  end

  test "new preserves the account review preselection in the searchable picker" do
    account = accounts(:one)

    get new_transaction_url(account_id: account.id)

    assert_response :success
    assert_select "input#account_id[type='hidden'][value='#{account.id}']"
    assert_select "input#account_id_lookup[value*='#{account.account_number}']"
    assert_select "input#account_id_lookup[value*='#{account.account_reference}']"
  end

  test "create posts ADJ_CREDIT and redirects" do
    account = accounts(:one)
    assert_difference "BankingTransaction.count", 1 do
      assert_difference "TransactionReference.count", 2 do
        post transactions_url, params: {
          transaction: {
            transaction_code: "ADJ_CREDIT",
            account_id: account.id,
            amount: "100.50",
            memo: "Courtesy credit",
            reason_text: "Service recovery",
            reference_number: "MAN-20260309-001",
            external_reference: "CASE-42"
          }
        }
      end
    end
    assert_redirected_to transaction_path(BankingTransaction.last)
    transaction = BankingTransaction.last
    assert_equal "Courtesy credit", transaction.memo
    assert_equal "Service recovery", transaction.reason_text
    assert_equal "MAN-20260309-001", transaction.reference_number
    assert_equal "CASE-42", transaction.external_reference
    assert_equal [ "external_reference", "reference_number" ], transaction.transaction_references.order(:reference_type).pluck(:reference_type)
    follow_redirect!
    assert_match /posted successfully/i, flash[:notice]
  end

  test "preview preserves operational metadata for confirm step" do
    post transactions_url, params: {
      preview: "1",
      transaction: {
        transaction_code: "ADJ_CREDIT",
        account_id: accounts(:one).id,
        amount: "25.00",
        memo: "Preview memo",
        reason_text: "Preview reason",
        reference_number: "MAN-20260309-002",
        external_reference: "CASE-99"
      }
    }

    assert_response :success
    assert_select "input[type=hidden][name='transaction[memo]'][value='Preview memo']"
    assert_select "input[type=hidden][name='transaction[reason_text]'][value='Preview reason']"
    assert_select "input[type=hidden][name='transaction[reference_number]'][value='MAN-20260309-002']"
    assert_select "input[type=hidden][name='transaction[external_reference]'][value='CASE-99']"
  end

  test "preview preserves fee and ach fields for confirm step" do
    post transactions_url, params: {
      preview: "1",
      transaction: {
        transaction_code: "ACH_DEBIT",
        account_id: accounts(:one).id,
        amount: "25.00",
        ach_trace_number: "123456789012345",
        ach_effective_date: "2026-03-08",
        ach_batch_reference: "FILE-20260308",
        authorization_reference: "AUTH-22",
        authorization_source: "signed form"
      }
    }

    assert_response :success
    assert_select "input[type=hidden][name='transaction[ach_trace_number]'][value='123456789012345']"
    assert_select "input[type=hidden][name='transaction[authorization_reference]'][value='AUTH-22']"
    assert_select "input[type=hidden][name='transaction[ach_batch_reference]'][value='FILE-20260308']"
  end

  test "show renders transaction" do
    txn = BankingTransaction.create!(
      transaction_type: "ADJ_CREDIT",
      branch: branches(:one),
      status: "posted",
      business_date: business_dates(:one).business_date
    )
    get transaction_url(txn)
    assert_response :success
  end

  test "show renders structured references" do
    get transaction_url(BankingTransaction.find_by!(reference_number: "TXN-002"))

    assert_response :success
    assert_select "h2", text: /Structured References/
    assert_select "td", text: "reference_number"
    assert_select "td", text: "TXN-002"
  end

  test "show renders transaction exceptions" do
    transaction = BankingTransaction.find_by!(reference_number: "TXN-002")
    TransactionException.create!(
      operational_transaction: transaction,
      exception_type: TransactionException::EXCEPTION_TYPE_OVERRIDE_REQUIRED,
      status: TransactionException::STATUS_OPEN,
      requires_override: true,
      reason_code: "reversal_threshold"
    )

    get transaction_url(transaction)

    assert_response :success
    assert_select "h2", text: /Transaction Exceptions/
    assert_select "td", text: "override_required"
    assert_select "td", text: "reversal_threshold"
  end

  test "create routes fee posts through fee workflow" do
    assert_difference "FeeAssessment.count", 1 do
      post transactions_url, params: {
        transaction: {
          transaction_code: "FEE_POST",
          account_id: accounts(:one).id,
          fee_type_id: fee_types(:maintenance).id,
          memo: "Manual maintenance assessment",
          reason_text: "Operator correction",
          reference_number: "FEE-20260309-001"
        }
      }
    end

    assert_redirected_to transaction_path(BankingTransaction.last)
    assessment = FeeAssessment.order(:id).last
    assert_equal accounts(:one).id, assessment.account_id
    assert_equal fee_types(:maintenance).id, assessment.fee_type_id
  end

  test "create routes ach entries through ach workflow" do
    post transactions_url, params: {
      transaction: {
        transaction_code: "ACH_DEBIT",
        account_id: accounts(:one).id,
        amount: "42.50",
        memo: "ACH debit",
        ach_trace_number: "123456789012345",
        ach_effective_date: "2026-03-08",
        ach_batch_reference: "FILE-20260308",
        authorization_reference: "AUTH-42",
        authorization_source: "signed form"
      }
    }

    assert_redirected_to transaction_path(BankingTransaction.last)
    transaction = BankingTransaction.last
    assert_equal "ACH_DEBIT", transaction.transaction_type
    assert_equal(
      [
        "ach_batch_reference",
        "ach_effective_date",
        "ach_trace_number",
        "authorization_reference",
        "authorization_source"
      ],
      transaction.transaction_references.order(:reference_type).pluck(:reference_type)
    )
  end

  test "reverse requires reverse_transactions permission" do
    batch = PostingEngine.post!(
      transaction_code: "ADJ_CREDIT",
      account_id: accounts(:one).id,
      amount_cents: 4000,
      business_date: business_dates(:one).business_date
    )
    txn = batch.operational_transaction

    delete logout_url
    post login_url, params: { username: "limiteduser", password: "secret" }
    post reverse_transaction_url(txn)

    assert_response :forbidden
    assert_match /do not have permission/i, flash[:alert]
  end

  test "reverse preview renders confirm screen" do
    batch = PostingEngine.post!(
      transaction_code: "ADJ_CREDIT",
      account_id: accounts(:one).id,
      amount_cents: 4000,
      business_date: business_dates(:one).business_date
    )

    get reverse_preview_transaction_url(batch.operational_transaction)

    assert_response :success
    assert_select "h1", text: /Reversal Preview/
    assert_select "form[action='#{reverse_transaction_path(batch.operational_transaction)}']"
  end

  test "reverse redirects to override request when threshold exceeded without approval" do
    batch = PostingEngine.post!(
      transaction_code: "ADJ_CREDIT",
      account_id: accounts(:one).id,
      amount_cents: 10_000,
      business_date: business_dates(:one).business_date
    )
    txn = batch.operational_transaction

    post reverse_transaction_url(txn)

    assert_redirected_to new_override_request_path(transaction_id: txn.id, request_type: "reversal")
    assert_match /require supervisor approval/i, flash[:alert]
  end

  private

  def ensure_fee_post_template!
    return if PostingTemplate.joins(:transaction_code).exists?(transaction_codes: { code: "FEE_POST" })

    posting_template = PostingTemplate.create!(
      transaction_code: transaction_codes(:fee_post),
      name: "Fee Assessment",
      description: "Debit account, credit fee income",
      active: true
    )
    PostingTemplateLeg.create!(
      posting_template: posting_template,
      leg_type: Bankcore::Enums::LEG_TYPE_DEBIT,
      account_source: Bankcore::Enums::ACCOUNT_SOURCE_CUSTOMER,
      description: "Debit customer account",
      position: 0
    )
    PostingTemplateLeg.create!(
      posting_template: posting_template,
      leg_type: Bankcore::Enums::LEG_TYPE_CREDIT,
      account_source: Bankcore::Enums::ACCOUNT_SOURCE_FIXED_GL,
      gl_account: gl_accounts(:three),
      description: "Credit fee income",
      position: 1
    )
  end

  def ensure_ach_template!
    return if PostingTemplate.joins(:transaction_code).exists?(transaction_codes: { code: "ACH_DEBIT" })

    transaction_code = TransactionCode.find_or_create_by!(code: "ACH_DEBIT") do |record|
      record.description = "Outgoing ACH"
      record.reversal_code = "ACH_CREDIT"
      record.active = true
    end
    posting_template = PostingTemplate.create!(
      transaction_code: transaction_code,
      name: "ACH Debit",
      description: "Debit account, credit ACH clearing",
      active: true
    )
    PostingTemplateLeg.create!(
      posting_template: posting_template,
      leg_type: Bankcore::Enums::LEG_TYPE_DEBIT,
      account_source: Bankcore::Enums::ACCOUNT_SOURCE_CUSTOMER,
      description: "Debit customer account",
      position: 0
    )
    PostingTemplateLeg.create!(
      posting_template: posting_template,
      leg_type: Bankcore::Enums::LEG_TYPE_CREDIT,
      account_source: Bankcore::Enums::ACCOUNT_SOURCE_FIXED_GL,
      gl_account: gl_accounts(:ten),
      description: "Credit ACH clearing",
      position: 1
    )
  end
end
