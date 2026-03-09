# frozen_string_literal: true

require "test_helper"

class TransactionEntry::DispatcherTest < ActiveSupport::TestCase
  setup do
    ensure_fee_post_template!
    ensure_ach_template!
  end

  test "posts fee workflow through fee posting service path" do
    request = TransactionEntry::Request.from_form(
      raw_params: {
        transaction_code: "FEE_POST",
        account_id: accounts(:one).id.to_s,
        fee_type_id: fee_types(:maintenance).id.to_s,
        reference_number: "FEE-REQ-1"
      },
      created_by_id: users(:one).id,
      business_date: business_dates(:one).business_date
    )

    assert_difference "FeeAssessment.count", 1 do
      batch = TransactionEntry::Dispatcher.post!(request: request)
      assert_equal "FEE_POST", batch.transaction_code
    end
  end

  test "previews ach workflow with structured context" do
    request = TransactionEntry::Request.from_form(
      raw_params: {
        transaction_code: "ACH_DEBIT",
        account_id: accounts(:one).id.to_s,
        amount: "10.00",
        ach_trace_number: "123456789012345",
        ach_effective_date: "2026-03-08",
        ach_batch_reference: "FILE-1",
        authorization_reference: "AUTH-1"
      },
      created_by_id: users(:one).id,
      business_date: business_dates(:one).business_date
    )

    preview = TransactionEntry::PreviewService.preview!(request: request)

    assert_equal 1000, preview[:amount_cents]
    assert_equal "123456789012345", preview[:context_rows].find { |label, _| label == "ACH Trace" }.last
    assert_equal 2, preview[:legs].size
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
