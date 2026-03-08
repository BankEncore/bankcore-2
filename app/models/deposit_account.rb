# frozen_string_literal: true

class DepositAccount < ApplicationRecord
  belongs_to :account

  validates :account_id, presence: true, uniqueness: true
end
