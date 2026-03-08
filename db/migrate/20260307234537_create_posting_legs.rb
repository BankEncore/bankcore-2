class CreatePostingLegs < ActiveRecord::Migration[8.1]
  def change
    create_table :posting_legs do |t|
      t.references :posting_batch, null: false, foreign_key: true
      t.string :leg_type, null: false
      t.string :ledger_scope, null: false
      t.references :gl_account, null: true, foreign_key: true
      t.references :account, null: true, foreign_key: true
      t.integer :amount_cents, null: false
      t.string :currency_code, null: false, default: "USD"
      t.integer :position

      t.timestamps
    end
  end
end
