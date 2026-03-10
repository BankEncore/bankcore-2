# frozen_string_literal: true

class DepositAccount < ApplicationRecord
  belongs_to :account

  validates :account_id, presence: true, uniqueness: true

  def resolved_check_writing_eligible
    return check_writing_eligible unless check_writing_eligible.nil?

    account.account_product&.check_writing_eligible?
  end
end
