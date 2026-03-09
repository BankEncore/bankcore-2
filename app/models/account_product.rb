# frozen_string_literal: true

class AccountProduct < ApplicationRecord
  include Bankcore::Enums

  STATEMENT_CYCLES = %w[monthly quarterly annual].freeze
  DEPOSIT_PRODUCT_CODES = %w[dda now savings cd].freeze
  INTEREST_BEARING_PRODUCT_CODES = %w[now savings cd].freeze

  belongs_to :liability_gl_account, class_name: "GlAccount", optional: true
  belongs_to :asset_gl_account, class_name: "GlAccount", optional: true

  has_many :accounts, dependent: :restrict_with_error

  validates :product_code, presence: true, uniqueness: true
  validates :name, presence: true
  validates :product_family, presence: true
  validates :currency_code, presence: true
  validates :statement_cycle, presence: true, inclusion: { in: STATEMENT_CYCLES }
  validates :status, presence: true, inclusion: { in: Bankcore::Enums::STATUSES }

  def deposit_product?
    product_family == "deposit" && DEPOSIT_PRODUCT_CODES.include?(product_code)
  end

  def default_deposit_type
    product_code if deposit_product?
  end

  def default_interest_bearing?
    INTEREST_BEARING_PRODUCT_CODES.include?(product_code)
  end

  def default_overdraft_policy
    return nil unless deposit_product?

    allow_overdraft ? "allow" : "disallow"
  end
end
