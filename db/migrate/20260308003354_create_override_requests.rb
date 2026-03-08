class CreateOverrideRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :override_requests do |t|
      t.string :request_type, null: false
      t.string :status, null: false
      t.references :requested_by, foreign_key: { to_table: :users }
      t.references :approved_by, foreign_key: { to_table: :users }
      t.references :branch, foreign_key: true
      t.references :operational_transaction, foreign_key: { to_table: :transactions }
      t.datetime :expires_at
      t.datetime :used_at
      t.text :reason_text

      t.timestamps
    end
  end
end
