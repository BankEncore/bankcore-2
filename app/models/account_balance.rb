# frozen_string_literal: true

class AccountBalance < ApplicationRecord
  belongs_to :account

  validates :account_id, presence: true
  validates :posted_balance_cents, presence: true, numericality: { only_integer: true }
  validates :available_balance_cents, presence: true, numericality: { only_integer: true }
end
