# frozen_string_literal: true

class JournalEntryLine < ApplicationRecord
  belongs_to :journal_entry
  belongs_to :gl_account
  belongs_to :branch, optional: true

  validates :journal_entry_id, presence: true
  validates :gl_account_id, presence: true
  validates :debit_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :credit_cents, numericality: { greater_than_or_equal_to: 0 }
end
