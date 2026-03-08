# frozen_string_literal: true

class AccountOwner < ApplicationRecord
  belongs_to :account
  belongs_to :party

  validates :account_id, presence: true
  validates :party_id, presence: true
end
