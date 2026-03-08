class CreateJournalEntryLines < ActiveRecord::Migration[8.1]
  def change
    create_table :journal_entry_lines do |t|
      t.references :journal_entry, null: false, foreign_key: true
      t.references :gl_account, null: false, foreign_key: true
      t.references :branch, null: true, foreign_key: true
      t.integer :debit_cents
      t.integer :credit_cents
      t.string :currency_code
      t.string :memo
      t.integer :position

      t.timestamps
    end
  end
end
