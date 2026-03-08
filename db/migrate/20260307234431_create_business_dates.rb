class CreateBusinessDates < ActiveRecord::Migration[8.1]
  def change
    create_table :business_dates do |t|
      t.date :business_date, null: false
      t.string :status, null: false, default: "open"
      t.datetime :opened_at
      t.datetime :closed_at

      t.timestamps
    end

    add_index :business_dates, :business_date, unique: true
  end
end
