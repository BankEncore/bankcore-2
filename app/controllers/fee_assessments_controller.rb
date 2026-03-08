# frozen_string_literal: true

class FeeAssessmentsController < ApplicationController
  def index
    @fee_assessments = FeeAssessment
      .includes(:account, :fee_type)
      .order(assessed_on: :desc, created_at: :desc)
      .limit(100)

    @fee_assessments = @fee_assessments.where(account_id: params[:account_id]) if params[:account_id].present?
  end
end
