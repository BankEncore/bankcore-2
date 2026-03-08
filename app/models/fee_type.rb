# frozen_string_literal: true

class FeeType < ApplicationRecord
  include Bankcore::Enums

  belongs_to :gl_account, optional: true
  has_many :fee_assessments, dependent: :restrict_with_error

  validates :code, presence: true, uniqueness: true
  validates :name, presence: true
  validates :default_amount_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :status, presence: true, inclusion: { in: Bankcore::Enums::STATUSES }
end
