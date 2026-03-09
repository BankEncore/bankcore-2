# frozen_string_literal: true

class AddAccountProductToAccounts < ActiveRecord::Migration[8.0]
  def change
    add_reference :accounts, :account_product, foreign_key: true
  end
end
