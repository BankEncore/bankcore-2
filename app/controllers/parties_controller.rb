# frozen_string_literal: true

class PartiesController < ApplicationController
  before_action :set_party, only: %i[show edit update]

  def index
    @parties = Party
      .includes(:primary_branch)
      .order(:party_number)
      .limit(100)
  end

  def show
    @account_owners = @party.account_owners.includes(:account)
  end

  def new
    @party = Party.new(status: Bankcore::Enums::STATUS_ACTIVE)
  end

  def create
    @party = Party.new(party_params)
    if @party.save
      redirect_to party_path(@party), notice: "Party created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @party.update(party_params)
      redirect_to party_path(@party), notice: "Party updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_party
    @party = Party.find(params[:id])
  end

  def party_params
    params.require(:party).permit(:party_number, :display_name, :party_type, :primary_branch_id, :status)
  end
end
