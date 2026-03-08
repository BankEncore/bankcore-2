# frozen_string_literal: true

class BusinessDatesController < ApplicationController
  def index
    @business_dates = BusinessDate
      .order(business_date: :desc)
      .limit(30)
    @current_open = BusinessDate.find_by(status: Bankcore::Enums::BUSINESS_DATE_OPEN)
  end

  def show
    @business_date = BusinessDate.find(params[:id])
    @transaction_count = BankingTransaction.where(business_date: @business_date.business_date).count
  end

  def close
    @business_date = BusinessDate.find(params[:id])
    BusinessDateEodService.run!(business_date: @business_date)
    redirect_to business_dates_path, notice: "Business date closed. Next date is now open."
  rescue BusinessDateEodService::EODValidationError => e
    redirect_to business_date_path(@business_date), alert: "EOD failed: #{e.message}"
  end
end
