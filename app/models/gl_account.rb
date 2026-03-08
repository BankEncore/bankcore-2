# frozen_string_literal: true

class GlAccount < ApplicationRecord
  include Bankcore::Enums

  belongs_to :parent_gl_account, class_name: "GlAccount", optional: true
  has_many :child_gl_accounts, class_name: "GlAccount", foreign_key: :parent_gl_account_id

  validates :gl_number, presence: true, uniqueness: true
  validates :name, presence: true
  validates :category, presence: true, inclusion: { in: Bankcore::Enums::GL_CATEGORIES }
  validates :normal_balance, presence: true, inclusion: { in: Bankcore::Enums::NORMAL_BALANCES }
  validates :status, presence: true, inclusion: { in: Bankcore::Enums::STATUSES }
end
