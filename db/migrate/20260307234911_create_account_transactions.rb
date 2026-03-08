class CreateAccountTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :account_transactions do |t|
      t.references :account, null: false, foreign_key: true
      t.references :posting_batch, null: false, foreign_key: true
      t.integer :amount_cents
      t.string :direction
      t.string :description
      t.integer :running_balance_cents
      t.date :business_date
      t.datetime :posted_at

      t.timestamps
    end
  end
end
