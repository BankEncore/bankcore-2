class CreateTransactionExceptions < ActiveRecord::Migration[8.1]
  def change
    create_table :transaction_exceptions do |t|
      t.references :transaction, null: false, foreign_key: true
      t.string :exception_type, null: false
      t.string :status, null: false
      t.boolean :requires_override, null: false, default: false
      t.string :reason_code, null: false
      t.datetime :resolved_at
      t.references :resolved_by, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :transaction_exceptions, [ :transaction_id, :status ], name: "index_transaction_exceptions_on_txn_and_status"
    add_index :transaction_exceptions, [ :transaction_id, :exception_type, :status ],
      name: "index_transaction_exceptions_on_txn_type_and_status"
  end
end
