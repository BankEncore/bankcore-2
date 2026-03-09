# frozen_string_literal: true

class FeeTypesController < ApplicationController
  before_action :set_fee_type, only: %i[edit update]
  before_action :set_form_options, only: %i[new create edit update]

  def index
    @fee_types = FeeType.includes(:gl_account, :fee_rules).order(:name)
  end

  def new
    @fee_type = FeeType.new(status: Bankcore::Enums::STATUS_ACTIVE)
  end

  def create
    @fee_type = FeeType.new(fee_type_params)
    if @fee_type.save
      redirect_to fee_types_path, notice: "Fee type created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @fee_type.update(fee_type_params)
      redirect_to fee_types_path, notice: "Fee type updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_fee_type
    @fee_type = FeeType.find(params[:id])
  end

  def set_form_options
    @gl_accounts = GlAccount.where(status: Bankcore::Enums::STATUS_ACTIVE).order(:gl_number)
  end

  def fee_type_params
    params.require(:fee_type).permit(:code, :name, :default_amount_cents, :gl_account_id, :status)
  end
end
