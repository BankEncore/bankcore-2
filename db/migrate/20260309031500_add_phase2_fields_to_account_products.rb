class AddPhase2FieldsToAccountProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :account_products, :statement_cycle, :string, null: false, default: "monthly"
    add_column :account_products, :allow_overdraft, :boolean, null: false, default: false
  end
end
