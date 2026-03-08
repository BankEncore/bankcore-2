class CreateParties < ActiveRecord::Migration[8.1]
  def change
    create_table :parties do |t|
      t.string :party_type, null: false
      t.string :party_number, null: false
      t.string :display_name, null: false
      t.string :status, null: false, default: "active"
      t.references :primary_branch, foreign_key: { to_table: :branches }
      t.date :opened_on
      t.date :closed_on

      t.timestamps
    end

    add_index :parties, :party_number, unique: true
  end
end
