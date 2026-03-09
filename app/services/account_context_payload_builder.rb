# frozen_string_literal: true

class AccountContextPayloadBuilder
  def self.build(account)
    new(account).build
  end

  def initialize(account)
    @account = account
    @helpers = ApplicationController.helpers
  end

  def build
    balance = @account.account_balances.first

    {
      id: @account.id,
      account_number: @account.account_number,
      account_reference: @account.account_reference,
      product_code: @account.product_code,
      product_name: @account.account_product&.name || @account.product_code,
      account_type: @account.account_type,
      status: @account.status,
      status_class: @helpers.status_pill_class(@account.status),
      currency_code: @account.currency_code,
      branch_code: @account.branch&.branch_code,
      primary_owner_name: primary_owner_name,
      posted_balance_cents: balance&.posted_balance_cents,
      available_balance_cents: balance&.available_balance_cents,
      posted_balance_display: currency_display(balance&.posted_balance_cents),
      available_balance_display: currency_display(balance&.available_balance_cents),
      display_label: display_label
    }
  end

  private

  def primary_owner_name
    primary_owner = @account.account_owners.to_a.min_by do |owner|
      [
        owner.is_primary ? 0 : 1,
        owner.id || 0
      ]
    end

    primary_owner&.party&.display_name
  end

  def currency_display(amount_cents)
    return "—" if amount_cents.nil?

    @helpers.number_to_currency(amount_cents / 100.0)
  end

  def display_label
    [
      @account.account_number,
      @account.account_reference,
      @account.product_code,
      @account.status
    ].compact.join(" — ")
  end
end
