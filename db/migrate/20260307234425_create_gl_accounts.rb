class CreateGlAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :gl_accounts do |t|
      t.string :gl_number, null: false
      t.string :name, null: false
      t.string :category, null: false
      t.string :normal_balance, null: false
      t.string :status, null: false, default: "active"

      t.timestamps
    end

    add_index :gl_accounts, :gl_number, unique: true
  end
end
