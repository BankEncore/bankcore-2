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
      .includes(:account_product)
      .where("account_number LIKE :query OR account_reference LIKE :query", query: like_query)
      .order(:account_number)
      .limit(MAX_RESULTS)
  end

  def account_payload(account)
    {
      id: account.id,
      account_number: account.account_number,
      account_reference: account.account_reference,
      product_code: account.product_code,
      status: account.status,
      display_label: [
        account.account_number,
        account.account_reference,
        account.product_code,
        account.status
      ].compact.join(" — ")
    }
  end
end
