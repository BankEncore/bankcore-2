# frozen_string_literal: true

# Idempotent console script to test the posting flow.
# Run with: bin/rails runner script/console_test_posting.rb
# Or paste into rails console.

branch = Branch.first
party = Party.find_or_create_by!(party_number: "P001") do |p|
  p.party_type = "person"
  p.display_name = "Test Customer"
  p.status = Bankcore::Enums::STATUS_ACTIVE
  p.primary_branch = branch
  p.opened_on = Date.current
end
account = Account.find_or_create_by!(account_number: "1001") do |a|
  a.account_type = "dda"
  a.branch = branch
  a.currency_code = "USD"
  a.status = Bankcore::Enums::STATUS_ACTIVE
  a.opened_on = Date.current
end
AccountOwner.find_or_create_by!(account: account, party: party) do |ao|
  ao.role_type = "primary"
  ao.is_primary = true
  ao.effective_on = Date.current
end

batch = PostingEngine.post!(transaction_code: "ADJ_CREDIT", account_id: account.id, amount_cents: 10000)
balance = account.account_balances.first&.posted_balance_cents

puts "Posted batch ##{batch.id}, account balance: #{balance} cents"
puts "Success!" if balance == 10000
