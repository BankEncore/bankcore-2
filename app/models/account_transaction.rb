# frozen_string_literal: true

class AccountTransaction < ApplicationRecord
  include PostedRecordImmutable

  belongs_to :account
  belongs_to :contra_account, class_name: "Account", optional: true
  belongs_to :posting_batch
  belongs_to :operational_transaction, class_name: "BankingTransaction", foreign_key: :transaction_id, optional: true

  def debit_cents
    direction == "debit" ? amount_cents : 0
  end

  def credit_cents
    direction == "credit" ? amount_cents : 0
  end

  validates :account_id, presence: true
  validates :posting_batch_id, presence: true
  validates :amount_cents, presence: true, numericality: { only_integer: true }
  validates :direction, presence: true, inclusion: { in: %w[debit credit] }
  validates :transaction_id, presence: true

  private

  def posted_record_immutable?
    posting_batch.status == Bankcore::Enums::STATUS_POSTED
  end
end
