class CreateCheckItems < ActiveRecord::Migration[8.1]
  def change
    create_table :check_items do |t|
      t.references :account, null: false, foreign_key: true
      t.string :check_number, null: false
      t.integer :amount_cents, null: false
      t.string :status, null: false, default: "posted"
      t.references :operational_transaction, null: false, foreign_key: { to_table: :transactions }
      t.references :posting_batch, null: false, foreign_key: true
      t.date :business_date, null: false

      t.timestamps
    end
  end
end
