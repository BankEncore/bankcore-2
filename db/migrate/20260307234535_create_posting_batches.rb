# frozen_string_literal: true

class CreatePostingBatches < ActiveRecord::Migration[8.1]
  def change
    create_table :posting_batches do |t|
      t.references :operational_transaction, null: true, foreign_key: { to_table: :transactions }
      t.string :posting_reference
      t.string :status, null: false, default: "draft"
      t.date :business_date, null: false
      t.datetime :posted_at
      t.references :reversal_of_batch, null: true, foreign_key: { to_table: :posting_batches }
      t.string :idempotency_key
      t.string :transaction_code, null: false

      t.timestamps
    end

    add_index :posting_batches, :idempotency_key, unique: true
  end
end
