# frozen_string_literal: true

class BranchesController < ApplicationController
  def index
    @branches = Branch
      .order(:branch_code)
      .limit(50)
  end

  def show
    @branch = Branch.find(params[:id])
    @accounts = @branch.accounts.where(status: Bankcore::Enums::STATUS_ACTIVE).order(:account_number).limit(50)
  end
end
