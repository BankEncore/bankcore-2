# frozen_string_literal: true

class User < ApplicationRecord
  include Bankcore::Enums

  has_secure_password

  belongs_to :primary_branch, class_name: "Branch", optional: true
  has_many :user_roles
  has_many :roles, through: :user_roles

  validates :username, presence: true, uniqueness: true
  validates :status, inclusion: { in: Bankcore::Enums::STATUSES }, allow_nil: true
end
