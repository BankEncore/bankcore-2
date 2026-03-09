# frozen_string_literal: true

require "test_helper"

class JournalProjectorTest < ActiveSupport::TestCase
  test "uses posting reference as journal entry reference number" do
    batch = PostingEngine.post!(
      transaction_code: "ADJ_CREDIT",
      account_id: accounts(:one).id,
      amount_cents: 1_000,
      business_date: business_dates(:one).business_date
    )

    assert_equal batch.posting_reference, batch.journal_entries.first.reference_number
  end

  test "projects account leg to product liability gl" do
    batch = PostingEngine.post!(
      transaction_code: "ADJ_CREDIT",
      account_id: accounts(:one).id,
      amount_cents: 1_000,
      business_date: business_dates(:one).business_date
    )

    lines = batch.journal_entries.first.journal_entry_lines.includes(:gl_account).order(:position)
    assert_equal 2, lines.size
    assert_equal %w[5190 2110], lines.map { |line| line.gl_account.gl_number }
    assert_equal [1_000, 0], [lines.first.debit_cents, lines.first.credit_cents]
    assert_equal [0, 1_000], [lines.second.debit_cents, lines.second.credit_cents]
  end

  test "projects internal transfer across product liability gls" do
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

    destination = Account.create!(
      account_number: "2009",
      account_type: "savings",
      account_product: account_products(:savings),
      branch: branches(:one),
      currency_code: "USD",
      status: "active"
    )
    DepositAccount.create!(account: destination, deposit_type: "savings", interest_bearing: true)

    batch = PostingEngine.post!(
      transaction_code: "XFER_INTERNAL",
      source_account_id: accounts(:one).id,
      destination_account_id: destination.id,
      amount_cents: 2_500,
      business_date: business_dates(:one).business_date
    )

    lines = batch.journal_entries.first.journal_entry_lines.includes(:gl_account).order(:position)
    assert_equal 2, lines.size
    assert_equal %w[2110 2130], lines.map { |line| line.gl_account.gl_number }
    assert_equal [2_500, 0], [lines.first.debit_cents, lines.first.credit_cents]
    assert_equal [0, 2_500], [lines.second.debit_cents, lines.second.credit_cents]
  end
end
