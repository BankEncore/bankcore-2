class CreateTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :transactions do |t|
      t.string :transaction_type
      t.string :channel
      t.references :branch, null: false, foreign_key: true
      t.string :status
      t.string :reference_number
      t.string :external_reference
      t.date :business_date
      t.datetime :initiated_at
      t.datetime :posted_at
      t.bigint :created_by_id
      t.bigint :approved_by_id

      t.timestamps
    end
  end
end
