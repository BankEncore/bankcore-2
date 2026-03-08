# frozen_string_literal: true

class JournalEntryLine < ApplicationRecord
  include PostedRecordImmutable

  belongs_to :journal_entry
  belongs_to :gl_account
  belongs_to :branch, optional: true

  validates :journal_entry_id, presence: true
  validates :gl_account_id, presence: true
  validates :debit_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :credit_cents, numericality: { greater_than_or_equal_to: 0 }

  private

  def posted_record_immutable?
    journal_entry.status == Bankcore::Enums::STATUS_POSTED
  end
end
