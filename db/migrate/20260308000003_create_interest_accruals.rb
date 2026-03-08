# frozen_string_literal: true

class CreateInterestAccruals < ActiveRecord::Migration[8.1]
  def change
    create_table :interest_accruals do |t|
      t.references :account, null: false, foreign_key: true
      t.date :accrual_date, null: false
      t.integer :amount_cents, null: false
      t.references :posting_batch, null: true, foreign_key: true
      t.string :status, default: "posted", null: false

      t.timestamps
    end

    add_index :interest_accruals, [ :account_id, :accrual_date ]
  end
end
