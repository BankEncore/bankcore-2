# frozen_string_literal: true

class AddCheckWritingEligibleToProductsAndDeposits < ActiveRecord::Migration[8.1]
  def change
    add_column :account_products, :check_writing_eligible, :boolean, null: false, default: false
    add_column :deposit_accounts, :check_writing_eligible, :boolean
  end
end
