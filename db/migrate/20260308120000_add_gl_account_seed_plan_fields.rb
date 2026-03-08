# frozen_string_literal: true

class AddGlAccountSeedPlanFields < ActiveRecord::Migration[8.1]
  def change
    add_column :gl_accounts, :allow_direct_posting, :boolean, default: true, null: false
    add_column :gl_accounts, :parent_gl_account_id, :bigint
    add_column :gl_accounts, :description, :string

    add_index :gl_accounts, :parent_gl_account_id
    add_foreign_key :gl_accounts, :gl_accounts, column: :parent_gl_account_id
  end
end
