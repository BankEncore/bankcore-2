class CreateTransactionCodes < ActiveRecord::Migration[8.1]
  def change
    create_table :transaction_codes do |t|
      t.string :code, null: false
      t.string :description
      t.string :reversal_code
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :transaction_codes, :code, unique: true
  end
end
