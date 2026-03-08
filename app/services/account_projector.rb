# frozen_string_literal: true

class AccountProjector
  def self.project!(posting_batch:)
    new(posting_batch: posting_batch).project!
  end

  def initialize(posting_batch:)
    @posting_batch = posting_batch
  end

  def project!
    return unless @posting_batch.status == Bankcore::Enums::STATUS_POSTED

    account_legs = @posting_batch.posting_legs.where(ledger_scope: Bankcore::Enums::LEDGER_SCOPE_ACCOUNT)

    account_legs.each do |leg|
      next if leg.account_id.blank?

      AccountTransaction.create!(
        account_id: leg.account_id,
        posting_batch_id: @posting_batch.id,
        amount_cents: leg.amount_cents,
        direction: leg.leg_type,
        description: "#{@posting_batch.transaction_code} ##{@posting_batch.id}",
        business_date: @posting_batch.business_date,
        posted_at: @posting_batch.posted_at
      )
    end

    BalanceRefreshService.refresh!(account_ids: account_legs.map(&:account_id).compact.uniq)
  end
end
