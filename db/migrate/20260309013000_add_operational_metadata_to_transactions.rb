class AddOperationalMetadataToTransactions < ActiveRecord::Migration[8.1]
  def change
    add_column :transactions, :memo, :text
    add_column :transactions, :reason_text, :text

    add_index :transactions, [ :business_date, :reference_number ], unique: true
  end
end
