# frozen_string_literal: true

class CreateFeeAssessments < ActiveRecord::Migration[8.1]
  def change
    create_table :fee_assessments do |t|
      t.references :account, null: false, foreign_key: true
      t.references :fee_type, null: false, foreign_key: true
      t.references :posting_batch, null: true, foreign_key: true
      t.integer :amount_cents, null: false
      t.date :assessed_on, null: false
      t.string :status, default: "posted", null: false

      t.timestamps
    end

    add_index :fee_assessments, [ :account_id, :assessed_on ]
  end
end
