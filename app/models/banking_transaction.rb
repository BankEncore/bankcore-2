# frozen_string_literal: true

class BankingTransaction < ApplicationRecord
  include Bankcore::Enums

  self.table_name = "transactions"

  belongs_to :branch
  belongs_to :created_by, class_name: "User", optional: true
  has_many :account_transactions, foreign_key: :transaction_id, dependent: :nullify
  has_one :posting_batch, foreign_key: :operational_transaction_id

  validates :transaction_type, presence: true
  validates :status, presence: true, inclusion: { in: Bankcore::Enums::POSTING_STATUSES }
  validates :business_date, presence: true
  validates :reference_number, uniqueness: { scope: :business_date }, allow_blank: true
end
