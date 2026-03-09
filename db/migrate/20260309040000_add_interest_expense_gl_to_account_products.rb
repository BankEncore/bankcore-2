class AddInterestExpenseGlToAccountProducts < ActiveRecord::Migration[8.1]
  def up
    add_reference :account_products, :interest_expense_gl_account, foreign_key: { to_table: :gl_accounts }

    execute <<~SQL.squish
      UPDATE account_products
      INNER JOIN gl_accounts ON gl_accounts.gl_number = CASE account_products.product_code
        WHEN 'now' THEN '5120'
        WHEN 'savings' THEN '5130'
        WHEN 'cd' THEN '5130'
        ELSE NULL
      END
      SET account_products.interest_expense_gl_account_id = gl_accounts.id
      WHERE account_products.interest_expense_gl_account_id IS NULL
        AND account_products.product_code IN ('now', 'savings', 'cd')
    SQL
  end

  def down
    remove_reference :account_products, :interest_expense_gl_account, foreign_key: { to_table: :gl_accounts }
  end
end
