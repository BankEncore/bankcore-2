class CreateInterestPostingApplications < ActiveRecord::Migration[8.1]
  def change
    create_table :interest_posting_applications do |t|
      t.references :interest_accrual, null: false, foreign_key: true, index: { unique: true }
      t.references :posting_batch, null: false, foreign_key: true
      t.date :posted_on, null: false

      t.timestamps
    end

    add_index :interest_posting_applications,
      [ :posting_batch_id, :interest_accrual_id ],
      unique: true,
      name: "index_interest_posting_applications_on_batch_and_accrual"
  end
end
