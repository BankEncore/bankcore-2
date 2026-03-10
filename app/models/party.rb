# frozen_string_literal: true

class Party < ApplicationRecord
  include Bankcore::Enums

  belongs_to :primary_branch, class_name: "Branch", optional: true
  has_many :account_owners
  has_many :accounts, through: :account_owners
  has_many :bank_drafts_as_remitter, class_name: "BankDraft", foreign_key: :remitter_party_id

  validates :party_type, presence: true, inclusion: { in: Bankcore::Enums::PARTY_TYPES }
  validates :display_name, presence: true
  validates :status, presence: true, inclusion: { in: Bankcore::Enums::STATUSES }
end
