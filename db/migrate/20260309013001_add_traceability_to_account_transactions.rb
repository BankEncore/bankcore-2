class AddTraceabilityToAccountTransactions < ActiveRecord::Migration[8.1]
  def change
    add_reference :account_transactions, :transaction, foreign_key: { to_table: :transactions }
    add_reference :account_transactions, :contra_account, foreign_key: { to_table: :accounts }
  end
end
