class CreateDepositAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :deposit_accounts do |t|
      t.references :account, null: false, foreign_key: true, index: { unique: true }
      t.string :deposit_type
      t.boolean :interest_bearing
      t.string :overdraft_policy
      t.integer :minimum_balance_cents

      t.timestamps
    end
  end
end
