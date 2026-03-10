# frozen_string_literal: true

class CustomerLookupsController < ApplicationController
  MAX_RESULTS = 20

  def show
    @query = params[:q].to_s.strip
    @party_results = @query.present? ? matched_parties(@query) : Party.none
    @account_results = @query.present? ? matched_accounts(@query) : Account.none
  end

  private

  def matched_parties(query)
    like_query = like_query_for(query)

    Party
      .includes(:primary_branch, account_owners: :account)
      .where(status: Bankcore::Enums::STATUS_ACTIVE)
      .where("party_number LIKE :query OR display_name LIKE :query", query: like_query)
      .order(:display_name, :party_number)
      .limit(MAX_RESULTS)
  end

  def matched_accounts(query)
    like_query = like_query_for(query)

    Account
      .where(status: Bankcore::Enums::STATUS_ACTIVE)
      .includes(:account_product, :branch, :account_balances, account_owners: :party)
      .where("account_number LIKE :query OR account_reference LIKE :query", query: like_query)
      .order(:account_number)
      .limit(MAX_RESULTS)
  end

  def like_query_for(query)
    escaped_query = ActiveRecord::Base.sanitize_sql_like(query)
    "%#{escaped_query}%"
  end
end
