# frozen_string_literal: true

class TrialBalanceQuery
  SummaryRow = Struct.new(
    :gl_account,
    :debit_cents,
    :credit_cents,
    :net_cents,
    :balance_side,
    keyword_init: true
  ) do
    def net_amount_cents
      net_cents.abs
    end

    def zero_activity?
      debit_cents.zero? && credit_cents.zero?
    end
  end

  DetailRow = Struct.new(
    :journal_reference,
    :posting_reference,
    :business_date,
    :posted_at,
    :branch_name,
    :debit_cents,
    :credit_cents,
    :transaction_type,
    :transaction_reference_number,
    :operational_transaction_id,
    keyword_init: true
  ) do
    def net_cents
      debit_cents - credit_cents
    end

    def net_amount_cents
      net_cents.abs
    end

    def balance_side
      return "debit" if net_cents.positive?
      return "credit" if net_cents.negative?

      "flat"
    end
  end

  attr_reader :business_date, :include_zero

  def initialize(business_date:, include_zero: true)
    @business_date = business_date
    @include_zero = include_zero
  end

  def summary_rows
    @summary_rows ||= begin
      aggregate_lookup = summary_aggregates_by_gl_account_id
      rows = active_gl_accounts.map do |gl_account|
        aggregate = aggregate_lookup.fetch(gl_account.id, {})
        build_summary_row(
          gl_account: gl_account,
          debit_cents: aggregate[:debit_cents].to_i,
          credit_cents: aggregate[:credit_cents].to_i
        )
      end

      include_zero ? rows : rows.reject(&:zero_activity?)
    end
  end

  def totals
    rows = summary_rows

    {
      debit_cents: rows.sum(&:debit_cents),
      credit_cents: rows.sum(&:credit_cents),
      net_cents: rows.sum(&:net_cents)
    }
  end

  def summary_row_for(gl_account_id)
    summary_rows.find { |row| row.gl_account.id == gl_account_id.to_i } ||
      build_summary_row(gl_account: active_gl_accounts.find(gl_account_id), debit_cents: 0, credit_cents: 0)
  end

  def detail_rows(gl_account_id:)
    journal_lines_for(gl_account_id).map do |line|
      posting_batch = line.journal_entry.posting_batch
      operational_transaction = posting_batch.operational_transaction

      DetailRow.new(
        journal_reference: line.journal_entry.reference_number,
        posting_reference: posting_batch.posting_reference,
        business_date: line.journal_entry.business_date,
        posted_at: line.journal_entry.posted_at,
        branch_name: line.branch&.name,
        debit_cents: line.debit_cents,
        credit_cents: line.credit_cents,
        transaction_type: operational_transaction&.transaction_type,
        transaction_reference_number: operational_transaction&.reference_number,
        operational_transaction_id: operational_transaction&.id
      )
    end
  end

  def detail_totals(gl_account_id:)
    rows = detail_rows(gl_account_id: gl_account_id)

    {
      debit_cents: rows.sum(&:debit_cents),
      credit_cents: rows.sum(&:credit_cents),
      net_cents: rows.sum(&:net_cents)
    }
  end

  private

  def active_gl_accounts
    @active_gl_accounts ||= GlAccount
      .where(status: Bankcore::Enums::STATUS_ACTIVE)
      .order(:gl_number)
  end

  def summary_aggregates_by_gl_account_id
    JournalEntryLine
      .joins(:journal_entry)
      .where(journal_entries: { business_date: business_date })
      .group(:gl_account_id)
      .pluck(
        :gl_account_id,
        Arel.sql("COALESCE(SUM(journal_entry_lines.debit_cents), 0)"),
        Arel.sql("COALESCE(SUM(journal_entry_lines.credit_cents), 0)")
      )
      .each_with_object({}) do |(gl_account_id, debit_cents, credit_cents), result|
        result[gl_account_id] = {
          debit_cents: debit_cents.to_i,
          credit_cents: credit_cents.to_i
        }
      end
  end

  def journal_lines_for(gl_account_id)
    JournalEntryLine
      .includes(:branch, journal_entry: { posting_batch: :operational_transaction })
      .joins(:journal_entry)
      .where(gl_account_id: gl_account_id, journal_entries: { business_date: business_date })
      .order(Arel.sql("journal_entries.posted_at ASC, journal_entry_lines.position ASC, journal_entry_lines.id ASC"))
  end

  def build_summary_row(gl_account:, debit_cents:, credit_cents:)
    net_cents = debit_cents - credit_cents

    SummaryRow.new(
      gl_account: gl_account,
      debit_cents: debit_cents,
      credit_cents: credit_cents,
      net_cents: net_cents,
      balance_side: balance_side_for(net_cents)
    )
  end

  def balance_side_for(net_cents)
    return "debit" if net_cents.positive?
    return "credit" if net_cents.negative?

    "flat"
  end
end
