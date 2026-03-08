# frozen_string_literal: true

class JournalEntry < ApplicationRecord
  include Bankcore::Enums

  belongs_to :posting_batch
  has_many :journal_entry_lines, dependent: :destroy

  validates :posting_batch_id, presence: true
  validates :status, presence: true, inclusion: { in: Bankcore::Enums::POSTING_STATUSES }
  validates :business_date, presence: true
end
