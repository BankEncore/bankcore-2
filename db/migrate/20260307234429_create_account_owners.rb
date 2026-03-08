class CreateAccountOwners < ActiveRecord::Migration[8.1]
  def change
    create_table :account_owners do |t|
      t.references :account, null: false, foreign_key: true
      t.references :party, null: false, foreign_key: true
      t.string :role_type
      t.boolean :is_primary
      t.date :effective_on
      t.date :ends_on

      t.timestamps
    end
  end
end
