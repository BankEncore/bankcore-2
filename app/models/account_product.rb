# frozen_string_literal: true

class AccountProduct < ApplicationRecord
  include Bankcore::Enums

  belongs_to :liability_gl_account, class_name: "GlAccount", optional: true
  belongs_to :asset_gl_account, class_name: "GlAccount", optional: true

  has_many :accounts, dependent: :restrict_with_error

  validates :product_code, presence: true, uniqueness: true
  validates :name, presence: true
  validates :product_family, presence: true
  validates :currency_code, presence: true
  validates :status, presence: true, inclusion: { in: Bankcore::Enums::STATUSES }
end
