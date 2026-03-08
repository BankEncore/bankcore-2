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
      create_journal_lines(journal_entry)
    end
  end

  private

  def create_journal_entry
    JournalEntry.create!(
      posting_batch_id: @posting_batch.id,
      reference_number: "JE-#{@posting_batch.id}",
      status: Bankcore::Enums::STATUS_POSTED,
      business_date: @posting_batch.business_date,
      posted_at: @posting_batch.posted_at
    )
  end

  def create_journal_lines(journal_entry)
    gl_legs = @posting_batch.posting_legs.where(ledger_scope: Bankcore::Enums::LEDGER_SCOPE_GL)
    branch_id = resolve_branch_id

    gl_legs.each_with_index do |leg, idx|
      debit_cents = leg.leg_type == Bankcore::Enums::LEG_TYPE_DEBIT ? leg.amount_cents : 0
      credit_cents = leg.leg_type == Bankcore::Enums::LEG_TYPE_CREDIT ? leg.amount_cents : 0

      JournalEntryLine.create!(
        journal_entry_id: journal_entry.id,
        gl_account_id: leg.gl_account_id,
        branch_id: branch_id,
        debit_cents: debit_cents,
        credit_cents: credit_cents,
        currency_code: leg.currency_code,
        position: idx
      )
    end
  end

  def resolve_branch_id
    @posting_batch.operational_transaction&.branch_id || Branch.first&.id
  end
end
