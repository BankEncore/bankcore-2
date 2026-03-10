# frozen_string_literal: true

class CreateBankDrafts < ActiveRecord::Migration[8.1]
  def change
    create_table :bank_drafts do |t|
      t.string :instrument_type, null: false
      t.string :instrument_number, null: false
      t.integer :amount_cents, null: false
      t.string :currency_code, null: false, default: "USD"
      t.string :payee_name, null: false
      t.date :issue_date, null: false
      t.string :status, null: false
      t.text :memo
      t.date :expires_at

      t.references :remitter_party, null: false, foreign_key: { to_table: :parties }
      t.references :account, foreign_key: true
      t.references :branch, null: false, foreign_key: true
      t.references :issued_by, foreign_key: { to_table: :users }
      t.references :voided_by, foreign_key: { to_table: :users }
      t.references :cleared_by, foreign_key: { to_table: :users }
      t.references :operational_transaction, foreign_key: { to_table: :transactions }
      t.references :posting_batch, foreign_key: true

      t.datetime :voided_at
      t.string :void_reason
      t.datetime :cleared_at
      t.string :clearing_reference

      t.timestamps
    end

    add_index :bank_drafts, [:instrument_type, :instrument_number],
      unique: true,
      name: "index_bank_drafts_on_type_and_number"
    add_index :bank_drafts, :status
    add_index :bank_drafts, :issue_date
  end
end
