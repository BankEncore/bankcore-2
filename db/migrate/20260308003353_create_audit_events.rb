class CreateAuditEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_events do |t|
      t.string :event_type, null: false
      t.string :actor_type
      t.bigint :actor_id
      t.string :target_type
      t.bigint :target_id
      t.string :action, null: false
      t.string :status
      t.date :business_date
      t.datetime :occurred_at, null: false
      t.text :metadata_json

      t.timestamps
    end

    add_index :audit_events, [ :event_type, :occurred_at ]
    add_index :audit_events, [ :target_type, :target_id ]
  end
end
