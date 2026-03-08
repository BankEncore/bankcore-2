# frozen_string_literal: true

class BusinessDate < ApplicationRecord
  include Bankcore::Enums

  validates :business_date, presence: true, uniqueness: true
  validates :status, presence: true, inclusion: { in: Bankcore::Enums::BUSINESS_DATE_STATUSES }
end
