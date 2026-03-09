# frozen_string_literal: true

class InterestRulesController < ApplicationController
  before_action :set_account_product, only: %i[new create]
  before_action :set_interest_rule, only: %i[edit update]

  def new
    @interest_rule = @account_product.interest_rules.new(
      day_count_method: InterestRule::DAY_COUNT_METHOD_ACTUAL_365,
      posting_cadence: InterestRule::POSTING_CADENCE_MONTHLY
    )
  end

  def create
    @interest_rule = @account_product.interest_rules.new(interest_rule_params)
    if @interest_rule.save
      redirect_to account_product_path(@account_product), notice: "Interest rule created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @interest_rule.update(interest_rule_params)
      redirect_to account_product_path(@interest_rule.account_product), notice: "Interest rule updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_account_product
    @account_product = AccountProduct.find(params[:account_product_id])
  end

  def set_interest_rule
    @interest_rule = InterestRule.find(params[:id])
    @account_product = @interest_rule.account_product
  end

  def interest_rule_params
    params.require(:interest_rule).permit(
      :rate,
      :day_count_method,
      :posting_cadence,
      :effective_on,
      :ends_on
    )
  end
end
