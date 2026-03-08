class CreateBranches < ActiveRecord::Migration[8.1]
  def change
    create_table :branches do |t|
      t.string :branch_code, null: false
      t.string :name, null: false
      t.string :timezone_name, default: "America/New_York"
      t.string :status, null: false, default: "active"
      t.date :opened_on
      t.date :closed_on

      t.timestamps
    end

    add_index :branches, :branch_code, unique: true
  end
end
