class CreateAccountBalances < ActiveRecord::Migration[8.1]
  def change
    create_table :account_balances do |t|
      t.references :account, null: false, foreign_key: true, index: { unique: true }
      t.integer :posted_balance_cents
      t.integer :available_balance_cents
      t.datetime :as_of_at

      t.timestamps
    end
  end
end
