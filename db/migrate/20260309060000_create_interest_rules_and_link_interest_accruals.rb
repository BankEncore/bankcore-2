class CreateInterestRulesAndLinkInterestAccruals < ActiveRecord::Migration[8.1]
  def change
    create_table :interest_rules do |t|
      t.references :account_product, null: false, foreign_key: true
      t.decimal :rate, precision: 8, scale: 6, null: false
      t.string :day_count_method, null: false, default: "actual_365"
      t.string :posting_cadence, null: false, default: "monthly"
      t.date :effective_on
      t.date :ends_on

      t.timestamps
    end

    add_index :interest_rules, [ :account_product_id, :effective_on ], name: "index_interest_rules_on_product_and_effective_on"
    add_reference :interest_accruals, :interest_rule, foreign_key: true
  end
end
