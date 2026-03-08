class CreatePostingTemplates < ActiveRecord::Migration[8.1]
  def change
    create_table :posting_templates do |t|
      t.references :transaction_code, null: false, foreign_key: true
      t.string :name
      t.string :description
      t.boolean :active

      t.timestamps
    end
  end
end
