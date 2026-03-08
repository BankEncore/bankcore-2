class CreateAccountHolds < ActiveRecord::Migration[8.1]
  def change
    create_table :account_holds do |t|
      t.references :account, null: false, foreign_key: true
      t.string :hold_type, null: false
      t.integer :amount_cents, null: false
      t.string :status, null: false
      t.string :reason_code
      t.date :effective_on, null: false
      t.date :release_on
      t.datetime :released_at

      t.timestamps
    end

    add_index :account_holds, [:account_id, :status]
  end
end
