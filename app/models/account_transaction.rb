# frozen_string_literal: true

class AccountTransaction < ApplicationRecord
  belongs_to :account
  belongs_to :posting_batch

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
end
