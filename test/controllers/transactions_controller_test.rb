# frozen_string_literal: true

require "test_helper"

class TransactionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    post login_url, params: { username: "testuser", password: "secret" }
    ensure_ach_template!
    ensure_fee_post_template!
    ensure_internal_transfer_template!
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
    upsert_balance(account, posted_balance_cents: 10_000, available_balance_cents: 9_500, average_balance_cents: 8_000)

    get new_transaction_url(account_id: account.id)

    assert_response :success
    assert_select "input#account_id[type='hidden'][value='#{account.id}']"
    assert_select "input#account_id_lookup[value*='#{account.account_number}']"
    assert_select "input#account_id_lookup[value*='#{account.account_reference}']"
    assert_select "h3", text: "Selected Account"
    assert_select ".ui-kv-label", text: "Primary Owner"
    assert_select ".ui-kv-value", text: /Test Customer/
    assert_select ".ui-kv-label", text: "Available Balance"
    assert_select ".ui-kv-value.ui-mono", text: /\$95\.00/
    assert_select ".ui-kv-label", text: "Posted Balance"
    assert_select ".ui-kv-value.ui-mono", text: /\$100\.00/
  end

  test "create posts XFER_INTERNAL with server-generated memo when blank" do
    upsert_balance(accounts(:one), posted_balance_cents: 10_000, available_balance_cents: 10_000, average_balance_cents: 8_000)
    upsert_balance(accounts(:two), posted_balance_cents: 25_000, available_balance_cents: 25_000, average_balance_cents: 24_000)

    assert_difference "BankingTransaction.count", 1 do
      post transactions_url, params: {
        transaction: {
          transaction_code: "XFER_INTERNAL",
          source_account_id: accounts(:one).id,
          destination_account_id: accounts(:two).id,
          amount: "50.00",
          memo: "",
          reference_number: ""
        }
      }
    end

    assert_redirected_to transaction_path(BankingTransaction.last)
    transaction = BankingTransaction.last
    assert_equal "Internal transfer: 1001 → 3001", transaction.memo
    assert_match /\AMAN-XFER_INTERNAL-\d{12}\z/, transaction.reference_number
    follow_redirect!
    assert_match /posted successfully/i, flash[:notice]
  end

  test "preview with blank memo for transfer generates default and preserves through confirm post" do
    upsert_balance(accounts(:one), posted_balance_cents: 10_000, available_balance_cents: 10_000, average_balance_cents: 8_000)
    upsert_balance(accounts(:two), posted_balance_cents: 25_000, available_balance_cents: 25_000, average_balance_cents: 24_000)

    post transactions_url, params: {
      preview: "1",
      transaction: {
        transaction_code: "XFER_INTERNAL",
        source_account_id: accounts(:one).id,
        destination_account_id: accounts(:two).id,
        amount: "25.00",
        memo: "",
        reference_number: ""
      }
    }

    assert_response :success
    assert_select "input[type=hidden][name='transaction[memo]']", 1
    doc = Nokogiri::HTML(response.body)
    memo_input = doc.at_css("input[type=hidden][name='transaction[memo]']")
    assert memo_input, "hidden memo field should be present"
    generated_memo = memo_input["value"]
    assert_equal "Internal transfer: 1001 → 3001", generated_memo

    post transactions_url, params: {
      transaction: {
        transaction_code: "XFER_INTERNAL",
        source_account_id: accounts(:one).id,
        destination_account_id: accounts(:two).id,
        amount: "25.00",
        memo: generated_memo,
        reference_number: doc.at_css("input[type=hidden][name='transaction[reference_number]']")&.[]("value")
      }
    }

    assert_redirected_to transaction_path(BankingTransaction.last)
    assert_equal "Internal transfer: 1001 → 3001", BankingTransaction.last.memo
  end

  test "new renders transfer account context panels when transfer accounts are selected" do
    upsert_balance(accounts(:one), posted_balance_cents: 10_000, available_balance_cents: 9_500, average_balance_cents: 8_000)
    upsert_balance(accounts(:two), posted_balance_cents: 25_000, available_balance_cents: 25_000, average_balance_cents: 24_000)

    get new_transaction_url(
      transaction: {
        transaction_code: "XFER_INTERNAL",
        source_account_id: accounts(:one).id,
        destination_account_id: accounts(:two).id
      }
    )

    assert_response :success
    assert_select "h3", text: "From Account"
    assert_select "h3", text: "To Account"
    assert_select ".ui-kv-value", text: /DDA-1001/
    assert_select ".ui-kv-value", text: /SAV-3001/
    assert_select ".ui-kv-value.ui-mono", text: /\$250\.00/
  end

  test "create posts ADJ_CREDIT with server-generated reference when blank" do
    account = accounts(:one)
    assert_difference "BankingTransaction.count", 1 do
      post transactions_url, params: {
        transaction: {
          transaction_code: "ADJ_CREDIT",
          account_id: account.id,
          amount: "50.00",
          memo: "Auto ref test",
          reason_text: "Server default",
          reference_number: "",
          external_reference: nil
        }
      }
    end
    assert_redirected_to transaction_path(BankingTransaction.last)
    transaction = BankingTransaction.last
    assert_match /\AMAN-ADJ_CREDIT-\d{12}\z/, transaction.reference_number
    follow_redirect!
    assert_match /posted successfully/i, flash[:notice]
  end

  test "create preserves operator-supplied reference_number" do
    account = accounts(:one)
    post transactions_url, params: {
      transaction: {
        transaction_code: "ADJ_CREDIT",
        account_id: account.id,
        amount: "75.00",
        memo: "Override test",
        reason_text: "Operator ref",
        reference_number: "CUSTOM-REF-999",
        external_reference: nil
      }
    }

    assert_redirected_to transaction_path(BankingTransaction.last)
    assert_equal "CUSTOM-REF-999", BankingTransaction.last.reference_number
  end

  test "preview with blank reference generates default and preserves through confirm post" do
    account = accounts(:one)
    post transactions_url, params: {
      preview: "1",
      transaction: {
        transaction_code: "ADJ_CREDIT",
        account_id: account.id,
        amount: "33.00",
        memo: "Preview ref test",
        reason_text: "Generated default",
        reference_number: "",
        external_reference: nil
      }
    }

    assert_response :success
    assert_select "input[type=hidden][name='transaction[reference_number]']", 1
    doc = Nokogiri::HTML(response.body)
    input = doc.at_css("input[type=hidden][name='transaction[reference_number]']")
    assert input, "hidden reference_number field should be present"
    generated_ref = input["value"]
    assert_match /\AMAN-ADJ_CREDIT-\d{12}\z/, generated_ref

    post transactions_url, params: {
      transaction: {
        transaction_code: "ADJ_CREDIT",
        account_id: account.id,
        amount: "33.00",
        memo: "Preview ref test",
        reason_text: "Generated default",
        reference_number: generated_ref,
        external_reference: nil
      }
    }

    assert_redirected_to transaction_path(BankingTransaction.last)
    assert_equal generated_ref, BankingTransaction.last.reference_number
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
        "authorization_source",
        "reference_number"
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

  def ensure_internal_transfer_template!
    return if PostingTemplate.joins(:transaction_code).exists?(transaction_codes: { code: "XFER_INTERNAL" })

    xfer_code = TransactionCode.find_or_create_by!(code: "XFER_INTERNAL") do |code|
      code.description = "Internal account transfer"
      code.active = true
    end

    xfer_template = PostingTemplate.create!(
      transaction_code: xfer_code,
      name: "Internal Transfer",
      description: "Debit source, credit destination",
      active: true
    )

    PostingTemplateLeg.create!(
      posting_template: xfer_template,
      leg_type: Bankcore::Enums::LEG_TYPE_DEBIT,
      account_source: Bankcore::Enums::ACCOUNT_SOURCE_SOURCE,
      description: "Debit source account",
      position: 0
    )
    PostingTemplateLeg.create!(
      posting_template: xfer_template,
      leg_type: Bankcore::Enums::LEG_TYPE_CREDIT,
      account_source: Bankcore::Enums::ACCOUNT_SOURCE_DESTINATION,
      description: "Credit destination account",
      position: 1
    )
  end

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
