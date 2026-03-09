# frozen_string_literal: true

namespace :balances do
  desc "Refresh posted and available balances for accounts (usage: rake balances:refresh or rake balances:refresh ACCOUNT_IDS=1,2,3)"
  task refresh: :environment do
    ids = ENV["ACCOUNT_IDS"]&.split(",")&.map(&:strip)&.map(&:to_i)
    account_ids = ids.presence || Account.where(status: Bankcore::Enums::STATUS_ACTIVE).pluck(:id)

    if account_ids.empty?
      puts "No accounts to refresh."
      next
    end

    BalanceRefreshService.refresh!(account_ids: account_ids)
    puts "Refreshed #{account_ids.size} account(s)."
  end
end