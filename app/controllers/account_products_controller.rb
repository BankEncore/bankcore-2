# frozen_string_literal: true

class AccountProductsController < ApplicationController
  before_action :set_account_product, only: %i[show edit update]
  before_action :set_form_options, only: %i[new create edit update]

  def index
    @account_products = AccountProduct
      .includes(:liability_gl_account, :interest_expense_gl_account, :fee_rules, :interest_rules)
      .order(:name)
  end

  def show
    @fee_rules = @account_product.fee_rules.includes(:fee_type, :gl_account).ordered
    @interest_rules = @account_product.interest_rules.ordered
  end

  def new
    @account_product = AccountProduct.new(
      product_family: "deposit",
      currency_code: Bankcore::DEFAULT_CURRENCY,
      statement_cycle: "monthly",
      status: Bankcore::Enums::STATUS_ACTIVE
    )
  end

  def create
    @account_product = AccountProduct.new(account_product_params)
    if @account_product.save
      redirect_to account_product_path(@account_product), notice: "Account product created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @account_product.update(account_product_params)
      redirect_to account_product_path(@account_product), notice: "Account product updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_account_product
    @account_product = AccountProduct.find(params[:id])
  end

  def set_form_options
    @gl_accounts = GlAccount.where(status: Bankcore::Enums::STATUS_ACTIVE).order(:gl_number)
  end

  def account_product_params
    params.require(:account_product).permit(
      :product_code,
      :name,
      :product_family,
      :currency_code,
      :statement_cycle,
      :allow_overdraft,
      :liability_gl_account_id,
      :asset_gl_account_id,
      :interest_expense_gl_account_id,
      :status
    )
  end
end
