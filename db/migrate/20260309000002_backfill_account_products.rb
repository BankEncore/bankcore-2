# frozen_string_literal: true

class BackfillAccountProducts < ActiveRecord::Migration[8.0]
  class MigrationAccount < ApplicationRecord
    self.table_name = "accounts"
  end

  class MigrationAccountProduct < ApplicationRecord
    self.table_name = "account_products"
  end

  class MigrationGlAccount < ApplicationRecord
    self.table_name = "gl_accounts"
  end

  PRODUCT_GL_NUMBERS = {
    "dda" => "2110",
    "now" => "2120",
    "savings" => "2130",
    "cd" => "2130"
  }.freeze

  def up
    MigrationAccount.reset_column_information
    MigrationAccountProduct.reset_column_information

    PRODUCT_GL_NUMBERS.each do |product_code, gl_number|
      gl_account_id = MigrationGlAccount.find_by(gl_number: gl_number)&.id

      MigrationAccountProduct.find_or_create_by!(product_code: product_code) do |product|
        product.name = default_name_for(product_code)
        product.product_family = "deposit"
        product.currency_code = "USD"
        product.status = "active"
        product.liability_gl_account_id = gl_account_id
      end
    end

    MigrationAccount.where(account_product_id: nil, account_type: PRODUCT_GL_NUMBERS.keys).find_each do |account|
      product = MigrationAccountProduct.find_by(product_code: account.account_type)
      account.update_columns(account_product_id: product.id) if product
    end
  end

  def down
    # Keep backfilled product links in place on rollback.
  end

  private

  def default_name_for(product_code)
    case product_code
    when "dda" then "Noninterest-Bearing DDA"
    when "now" then "Interest-Bearing Demand"
    when "savings" then "Savings"
    when "cd" then "Time Deposit"
    else product_code.upcase
    end
  end
end
