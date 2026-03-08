# frozen_string_literal: true

class AccountOwnersController < ApplicationController
  def new
    @account = Account.find(params[:account_id])
    @parties = Party.where(status: Bankcore::Enums::STATUS_ACTIVE).order(:display_name)
    @account_owner = AccountOwner.new(account_id: @account.id)
  end

  def create
    @account = Account.find(params[:account_id])
    @account_owner = AccountOwner.new(account_owner_params)
    @account_owner.account_id = @account.id

    if @account_owner.save
      redirect_to account_path(@account), notice: "Owner added successfully."
    else
      @parties = Party.where(status: Bankcore::Enums::STATUS_ACTIVE).order(:display_name)
      render :new, status: :unprocessable_entity
    end
  end

  private

  def account_owner_params
    params.require(:account_owner).permit(:party_id, :role_type, :is_primary)
  end
end
