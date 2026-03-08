# frozen_string_literal: true

class CreateFeeTypes < ActiveRecord::Migration[8.1]
  def change
    create_table :fee_types do |t|
      t.string :code, null: false
      t.string :name, null: false
      t.integer :default_amount_cents, default: 0, null: false
      t.references :gl_account, null: true, foreign_key: { to_table: :gl_accounts }
      t.string :status, default: "active", null: false

      t.timestamps
    end

    add_index :fee_types, :code, unique: true
  end
end
