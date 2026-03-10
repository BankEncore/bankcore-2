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
    @account_owners = @party.account_owners.includes(account: [ :account_product, :branch, :account_balances ]).order(is_primary: :desc, id: :asc)
    @linked_accounts = @account_owners.map(&:account)
    @recent_activity = AccountTransaction
      .where(account_id: @linked_accounts.map(&:id))
      .includes(:account, :posting_batch)
      .order(posted_at: :desc, id: :desc)
      .limit(20)
  end

  def new
    @party = Party.new(status: Bankcore::Enums::STATUS_ACTIVE)
  end

  def create
    @party = Party.new(party_params)
    if @party.save
      redirect_to post_create_redirect_path, notice: post_create_notice
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

  def post_create_redirect_path
    return party_path(@party) unless safe_return_to_path.present?

    uri = URI.parse(safe_return_to_path)
    existing_params = Rack::Utils.parse_nested_query(uri.query)
    existing_params["party_id"] = @party.id.to_s
    uri.query = existing_params.to_query.presence
    uri.to_s
  rescue URI::InvalidURIError
    party_path(@party)
  end

  def post_create_notice
    if safe_return_to_path.present?
      "Customer created successfully. Continue the account opening workflow."
    else
      "Party created successfully."
    end
  end

  def safe_return_to_path
    return_to = params[:return_to].to_s
    return if return_to.blank?
    return unless return_to.start_with?("/")

    return_to
  end
end
