class AddInterestRateToDepositAccounts < ActiveRecord::Migration[8.1]
  def change
    add_column :deposit_accounts, :interest_rate_basis_points, :integer
  end
end
