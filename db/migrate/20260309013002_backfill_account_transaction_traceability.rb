class BackfillAccountTransactionTraceability < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      UPDATE account_transactions
      INNER JOIN posting_batches ON posting_batches.id = account_transactions.posting_batch_id
      SET account_transactions.transaction_id = posting_batches.operational_transaction_id
      WHERE account_transactions.transaction_id IS NULL
        AND posting_batches.operational_transaction_id IS NOT NULL
    SQL

    execute <<~SQL.squish
      UPDATE account_transactions
      INNER JOIN posting_batches ON posting_batches.id = account_transactions.posting_batch_id
      INNER JOIN posting_legs own_leg
        ON own_leg.posting_batch_id = posting_batches.id
       AND own_leg.account_id = account_transactions.account_id
      INNER JOIN posting_legs contra_leg
        ON contra_leg.posting_batch_id = posting_batches.id
       AND contra_leg.account_id IS NOT NULL
       AND contra_leg.account_id <> account_transactions.account_id
      SET account_transactions.contra_account_id = contra_leg.account_id
      WHERE posting_batches.transaction_code = 'XFER_INTERNAL'
        AND account_transactions.contra_account_id IS NULL
    SQL
  end

  def down
    execute "UPDATE account_transactions SET contra_account_id = NULL"
    execute "UPDATE account_transactions SET transaction_id = NULL"
  end
end
