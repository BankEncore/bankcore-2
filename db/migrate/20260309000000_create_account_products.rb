# frozen_string_literal: true

class CreateAccountProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :account_products do |t|
      t.string :product_code, null: false
      t.string :name, null: false
      t.string :product_family, null: false
      t.string :currency_code, null: false, default: "USD"
      t.string :status, null: false, default: "active"
      t.references :liability_gl_account, foreign_key: { to_table: :gl_accounts }
      t.references :asset_gl_account, foreign_key: { to_table: :gl_accounts }

      t.timestamps
    end

    add_index :account_products, :product_code, unique: true
  end
end
