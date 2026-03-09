# frozen_string_literal: true

class AccountsController < ApplicationController
  before_action :set_account, only: %i[show]

  def index
    @accounts = Account
      .includes(:branch, :account_balances)
      .where(status: Bankcore::Enums::STATUS_ACTIVE)
      .order(:account_number)
  end

  def show
    @balance = @account.account_balances.first
    @active_holds = @account.account_holds.where(status: Bankcore::Enums::HOLD_STATUS_ACTIVE).order(created_at: :desc)
    @transactions = @account.account_transactions
      .includes(:posting_batch)
      .order(posted_at: :desc, id: :desc)
      .limit(50)
  end

  def new
    @account = Account.new(
      status: Bankcore::Enums::STATUS_ACTIVE,
      opened_on: Date.current
    )
    set_form_options
  end

  def create
    @account = Account.new(account_params)
    @account.opened_on ||= Date.current
    @account.status ||= Bankcore::Enums::STATUS_ACTIVE
    apply_product_defaults!

    if @account.save
      create_deposit_account_if_needed!
      create_primary_owner_if_provided!
      redirect_to account_path(@account), notice: "Account created successfully."
    else
      @account.primary_party_id = params[:account][:primary_party_id]
      set_form_options
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_account
    @account = Account.find(params[:id])
  end

  def account_params
    params.require(:account).permit(:account_number, :account_product_id, :branch_id)
  end

  def create_deposit_account_if_needed!
    product = @account.account_product
    return unless product&.deposit_product?

    DepositAccount.create!(
      account_id: @account.id,
      deposit_type: product.default_deposit_type,
      interest_bearing: product.default_interest_bearing?,
      overdraft_policy: product.default_overdraft_policy
    )
  end

  def set_form_options
    @branches = Branch.where(status: Bankcore::Enums::STATUS_ACTIVE).order(:branch_code)
    @parties = Party.order(:display_name).limit(200)
    @account_products = AccountProduct.where(status: Bankcore::Enums::STATUS_ACTIVE).order(:name)
  end

  def create_primary_owner_if_provided!
    party_id = params[:account][:primary_party_id].presence
    return if party_id.blank?

    AccountOwner.create!(
      account_id: @account.id,
      party_id: party_id,
      role_type: "primary",
      is_primary: true,
      effective_on: Date.current
    )
  end

  def apply_product_defaults!
    return if @account.account_product.blank?

    @account.account_type = @account.account_product.product_code
    @account.currency_code = @account.account_product.currency_code
  end
end
