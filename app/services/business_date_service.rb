# frozen_string_literal: true

class BusinessDateService
  class NoOpenBusinessDateError < StandardError; end

  def self.current
    new.current
  end

  def current
    bd = BusinessDate.find_by(status: Bankcore::Enums::BUSINESS_DATE_OPEN)
    raise NoOpenBusinessDateError, "No open business date. Run db:seed to create one." unless bd

    bd.business_date
  end

  def self.open?(date)
    BusinessDate.exists?(business_date: date, status: Bankcore::Enums::BUSINESS_DATE_OPEN)
  end
end
