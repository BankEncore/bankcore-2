# frozen_string_literal: true

class Account < ApplicationRecord
  include Bankcore::Enums

  attr_accessor :primary_party_id

  belongs_to :branch
  belongs_to :account_product, optional: true
  has_many :account_owners
  has_many :parties, through: :account_owners
  has_one :deposit_account, dependent: :destroy
  has_many :account_transactions
  has_many :account_balances
  has_many :account_holds
  has_many :posting_legs
  has_many :fee_assessments
  has_many :interest_accruals

  validates :account_number, presence: true, uniqueness: true
  validates :account_type, presence: true, inclusion: { in: Bankcore::ACCOUNT_TYPES }
  validates :branch_id, presence: true
  validates :currency_code, presence: true
  validates :status, presence: true, inclusion: { in: Bankcore::Enums::STATUSES }

  def product_code
    account_product&.product_code || account_type
  end
end
