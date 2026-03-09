# frozen_string_literal: true

class FeeRulesController < ApplicationController
  before_action :set_account_product, only: %i[new create]
  before_action :set_fee_rule, only: %i[edit update]
  before_action :set_form_options, only: %i[new create edit update]

  def new
    @fee_rule = @account_product.fee_rules.new(
      method: FeeRule::METHOD_FIXED_AMOUNT,
      priority: next_priority(@account_product)
    )
  end

  def create
    @fee_rule = @account_product.fee_rules.new(fee_rule_params)
    if @fee_rule.save
      redirect_to account_product_path(@account_product), notice: "Fee rule created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @fee_rule.update(fee_rule_params)
      redirect_to account_product_path(@fee_rule.account_product), notice: "Fee rule updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_account_product
    @account_product = AccountProduct.find(params[:account_product_id])
  end

  def set_fee_rule
    @fee_rule = FeeRule.find(params[:id])
    @account_product = @fee_rule.account_product
  end

  def set_form_options
    @fee_types = FeeType.where(status: Bankcore::Enums::STATUS_ACTIVE).order(:name)
    @gl_accounts = GlAccount.where(status: Bankcore::Enums::STATUS_ACTIVE).order(:gl_number)
  end

  def fee_rule_params
    params.require(:fee_rule).permit(
      :fee_type_id,
      :priority,
      :method,
      :amount_cents,
      :gl_account_id,
      :effective_on,
      :ends_on
    )
  end

  def next_priority(account_product)
    account_product.fee_rules.maximum(:priority).to_i + 100
  end
end
