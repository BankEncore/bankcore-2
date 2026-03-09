class CreateFeeRulesAndLinkFeeAssessments < ActiveRecord::Migration[8.1]
  def change
    create_table :fee_rules do |t|
      t.references :fee_type, null: false, foreign_key: true
      t.references :account_product, null: false, foreign_key: true
      t.references :gl_account, foreign_key: true
      t.integer :priority, null: false, default: 100
      t.string :method, null: false, default: "fixed_amount"
      t.integer :amount_cents
      t.text :conditions_json
      t.date :effective_on
      t.date :ends_on

      t.timestamps
    end

    add_index :fee_rules, [ :fee_type_id, :account_product_id, :priority ], unique: true,
      name: "index_fee_rules_on_fee_type_product_priority"

    add_reference :fee_assessments, :fee_rule, foreign_key: true
  end
end
