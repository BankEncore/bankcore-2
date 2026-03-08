class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :username
      t.string :display_name
      t.string :email
      t.string :status
      t.references :primary_branch, foreign_key: { to_table: :branches }

      t.timestamps
    end
  end
end
