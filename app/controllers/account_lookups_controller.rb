# frozen_string_literal: true

class AccountLookupsController < ApplicationController
  MAX_RESULTS = 20

  before_action -> { require_permission(:post_transactions) }

  def index
    query = params[:q].to_s.strip
    accounts = query.present? ? matched_accounts(query) : Account.none

    render json: {
      accounts: accounts.map { |account| account_payload(account) }
    }
  end

  private

  def matched_accounts(query)
    escaped_query = ActiveRecord::Base.sanitize_sql_like(query)
    like_query = "%#{escaped_query}%"

    Account
      .where(status: Bankcore::Enums::STATUS_ACTIVE)
      .includes(:account_product, :branch, :account_balances, account_owners: :party)
      .where("account_number LIKE :query OR account_reference LIKE :query", query: like_query)
      .order(:account_number)
      .limit(MAX_RESULTS)
  end

  def account_payload(account)
    AccountContextPayloadBuilder.build(account)
  end
end
