class CreatePostingTemplateLegs < ActiveRecord::Migration[8.1]
  def change
    create_table :posting_template_legs do |t|
      t.references :posting_template, null: false, foreign_key: true
      t.references :gl_account, foreign_key: true
      t.string :leg_type
      t.string :account_source
      t.string :description
      t.integer :position

      t.timestamps
    end
  end
end
