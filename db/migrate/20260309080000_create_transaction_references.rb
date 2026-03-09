class CreateTransactionReferences < ActiveRecord::Migration[8.1]
  def up
    create_table :transaction_references do |t|
      t.references :transaction, null: false, foreign_key: true
      t.string :reference_type, null: false
      t.string :reference_value, null: false

      t.timestamps
    end

    add_index :transaction_references, [ :transaction_id, :reference_type, :reference_value ],
      unique: true,
      name: "index_transaction_references_on_txn_type_value"
    add_index :transaction_references, [ :reference_type, :reference_value ],
      name: "index_transaction_references_on_type_and_value"

    backfill_transaction_references!
  end

  def down
    drop_table :transaction_references
  end

  private

  def backfill_transaction_references!
    execute <<~SQL
      INSERT INTO transaction_references (transaction_id, reference_type, reference_value, created_at, updated_at)
      SELECT id, 'reference_number', reference_number, NOW(), NOW()
      FROM transactions
      WHERE reference_number IS NOT NULL AND reference_number <> ''
    SQL

    execute <<~SQL
      INSERT INTO transaction_references (transaction_id, reference_type, reference_value, created_at, updated_at)
      SELECT id, 'external_reference', external_reference, NOW(), NOW()
      FROM transactions
      WHERE external_reference IS NOT NULL AND external_reference <> ''
    SQL

    execute <<~SQL
      INSERT INTO transaction_references (transaction_id, reference_type, reference_value, created_at, updated_at)
      SELECT posting_batches.operational_transaction_id, 'idempotency_key', posting_batches.idempotency_key, NOW(), NOW()
      FROM posting_batches
      WHERE posting_batches.operational_transaction_id IS NOT NULL
        AND posting_batches.idempotency_key IS NOT NULL
        AND posting_batches.idempotency_key <> ''
    SQL
  end
end
