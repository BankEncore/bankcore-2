class AddAverageBalanceToAccountBalances < ActiveRecord::Migration[8.1]
  def up
    add_column :account_balances, :average_balance_cents, :integer, default: 0, null: false

    execute <<~SQL.squish
      UPDATE account_balances
      SET average_balance_cents = posted_balance_cents
      WHERE average_balance_cents = 0
    SQL
  end

  def down
    remove_column :account_balances, :average_balance_cents
  end
end
