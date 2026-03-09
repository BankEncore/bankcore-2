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
    contra_map = bilateral_contra_map(account_legs)

    account_legs.each do |leg|
      next if leg.account_id.blank?

      AccountTransaction.create!(
        account_id: leg.account_id,
        contra_account_id: contra_map[leg.account_id],
        posting_batch_id: @posting_batch.id,
        transaction_id: @posting_batch.operational_transaction_id,
        amount_cents: leg.amount_cents,
        direction: leg.leg_type,
        description: build_description(leg.account_id, contra_map[leg.account_id]),
        business_date: @posting_batch.business_date,
        posted_at: @posting_batch.posted_at
      )
    end

    BalanceRefreshService.refresh!(account_ids: account_legs.map(&:account_id).compact.uniq)
  end

  private

  def build_description(account_id, contra_account_id)
    transaction = @posting_batch.operational_transaction
    parts = []
    parts << (transaction&.memo.presence || transaction&.reason_text.presence || @posting_batch.transaction_code)
    parts << "Ref #{transaction.reference_number}" if transaction&.reference_number.present?

    if contra_account_id.present?
      contra_account_number = Account.find_by(id: contra_account_id)&.account_number
      parts << "Contra #{contra_account_number}" if contra_account_number.present?
    end

    parts.join(" | ").truncate(255)
  end

  def bilateral_contra_map(account_legs)
    account_ids = account_legs.map(&:account_id).compact.uniq
    return {} unless account_ids.size == 2

    {
      account_ids.first => account_ids.second,
      account_ids.second => account_ids.first
    }
  end
end
