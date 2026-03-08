# frozen_string_literal: true

class TransactionCode < ApplicationRecord
  has_many :posting_templates, dependent: :restrict_with_error

  validates :code, presence: true, uniqueness: true
  validates :active, inclusion: { in: [ true, false ] }
end
