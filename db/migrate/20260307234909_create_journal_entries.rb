class CreateJournalEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :journal_entries do |t|
      t.references :posting_batch, null: false, foreign_key: true
      t.string :reference_number
      t.string :status
      t.date :business_date
      t.datetime :posted_at

      t.timestamps
    end
  end
end
