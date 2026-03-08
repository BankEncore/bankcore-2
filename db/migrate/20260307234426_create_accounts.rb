class CreateAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :accounts do |t|
      t.string :account_number, null: false
      t.string :account_type, null: false
      t.references :branch, null: false, foreign_key: true
      t.string :currency_code, null: false, default: "USD"
      t.string :status, null: false, default: "active"
      t.date :opened_on
      t.date :closed_on

      t.timestamps
    end

    add_index :accounts, :account_number, unique: true
  end
end
