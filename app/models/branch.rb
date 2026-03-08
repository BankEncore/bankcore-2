# frozen_string_literal: true

class Branch < ApplicationRecord
  include Bankcore::Enums

  has_many :accounts
  has_many :parties, foreign_key: :primary_branch_id

  validates :branch_code, presence: true, uniqueness: true
  validates :name, presence: true
  validates :status, presence: true, inclusion: { in: Bankcore::Enums::STATUSES }
end
