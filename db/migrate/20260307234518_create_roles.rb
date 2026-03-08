class CreateRoles < ActiveRecord::Migration[8.1]
  def change
    create_table :roles do |t|
      t.string :code
      t.string :name
      t.text :description

      t.timestamps
    end
  end
end
