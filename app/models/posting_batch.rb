# frozen_string_literal: true

class PostingBatch < ApplicationRecord
  include Bankcore::Enums

  belongs_to :operational_transaction, class_name: "BankingTransaction", optional: true
  belongs_to :reversal_of_batch, class_name: "PostingBatch", optional: true
  has_many :posting_legs, dependent: :destroy
  has_many :journal_entries, dependent: :destroy
  has_many :fee_assessments
  has_many :interest_accruals
  has_one :reversal_batch, class_name: "PostingBatch", foreign_key: :reversal_of_batch_id

  validates :status, presence: true, inclusion: { in: Bankcore::Enums::POSTING_STATUSES }
  validates :business_date, presence: true
  validates :transaction_code, presence: true

  scope :posted, -> { where(status: Bankcore::Enums::STATUS_POSTED) }
end
