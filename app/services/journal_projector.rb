# frozen_string_literal: true

class JournalProjector
  def self.project!(posting_batch:)
    new(posting_batch: posting_batch).project!
  end

  def initialize(posting_batch:)
    @posting_batch = posting_batch
  end

  def project!
    return unless @posting_batch.status == Bankcore::Enums::STATUS_POSTED

    JournalEntry.transaction do
      journal_entry = create_journal_entry
      create_journal_lines(journal_entry, combined_journal_lines)
    end
  end

  private

  def create_journal_entry
    JournalEntry.create!(
      posting_batch_id: @posting_batch.id,
      reference_number: @posting_batch.posting_reference,
      status: Bankcore::Enums::STATUS_POSTED,
      business_date: @posting_batch.business_date,
      posted_at: @posting_batch.posted_at
    )
  end

  def create_journal_lines(journal_entry, lines)
    branch_id = resolve_branch_id

    lines.each_with_index do |line, idx|
      debit_cents = line[:leg_type] == Bankcore::Enums::LEG_TYPE_DEBIT ? line[:amount_cents] : 0
      credit_cents = line[:leg_type] == Bankcore::Enums::LEG_TYPE_CREDIT ? line[:amount_cents] : 0

      JournalEntryLine.create!(
        journal_entry_id: journal_entry.id,
        gl_account_id: line[:gl_account_id],
        branch_id: branch_id,
        debit_cents: debit_cents,
        credit_cents: credit_cents,
        currency_code: line[:currency_code],
        position: idx
      )
    end
  end

  def combined_journal_lines
    gl_lines + derived_account_lines
  end

  def gl_lines
    @posting_batch.posting_legs
      .where(ledger_scope: Bankcore::Enums::LEDGER_SCOPE_GL)
      .map do |leg|
        {
          leg_type: leg.leg_type,
          gl_account_id: leg.gl_account_id,
          amount_cents: leg.amount_cents,
          currency_code: leg.currency_code
        }
      end
  end

  def derived_account_lines
    @posting_batch.posting_legs
      .includes(account: :account_product)
      .where(ledger_scope: Bankcore::Enums::LEDGER_SCOPE_ACCOUNT)
      .map do |leg|
        gl_account = ProductGlResolver.resolve_account_gl(leg.account)
        raise ArgumentError, "No product GL mapping for account #{leg.account_id}" unless gl_account

        {
          leg_type: leg.leg_type,
          gl_account_id: gl_account.id,
          amount_cents: leg.amount_cents,
          currency_code: leg.currency_code
        }
      end
  end

  def resolve_branch_id
    @posting_batch.operational_transaction&.branch_id || Branch.first&.id
  end
end
