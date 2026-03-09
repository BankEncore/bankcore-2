class AddAccountReferenceToAccounts < ActiveRecord::Migration[8.1]
  def up
    add_column :accounts, :account_reference, :string

    execute <<~SQL.squish
      UPDATE accounts
      SET account_reference = account_number
      WHERE account_reference IS NULL OR account_reference = ''
    SQL

    change_column_null :accounts, :account_reference, false
    add_index :accounts, :account_reference, unique: true
  end

  def down
    remove_index :accounts, :account_reference
    remove_column :accounts, :account_reference
  end
end
