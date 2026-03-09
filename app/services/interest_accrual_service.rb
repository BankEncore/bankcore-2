# frozen_string_literal: true

class InterestAccrualService
  include Bankcore::Enums

  def self.accrue!(account_id:, amount_cents:, accrual_date: nil, idempotency_key: nil)
    new(account_id: account_id, amount_cents: amount_cents, accrual_date: accrual_date,
        idempotency_key: idempotency_key).accrue!
  end

  def initialize(account_id:, amount_cents:, accrual_date: nil, idempotency_key: nil)
    @account_id = account_id
    @amount_cents = amount_cents
    @accrual_date = accrual_date || BusinessDateService.current
    @idempotency_key = idempotency_key
  end

  def accrue!
    raise ArgumentError, "Amount must be non-negative" if @amount_cents.to_i < 0

    ActiveRecord::Base.transaction do
      expense_gl_account = resolve_interest_expense_gl_account!

      batch = PostingEngine.post!(
        transaction_code: "INT_ACCRUAL",
        account_id: @account_id,
        amount_cents: @amount_cents,
        business_date: @accrual_date,
        gl_account_id: expense_gl_account.id,
        idempotency_key: @idempotency_key,
        idempotency_context: {
          service: "interest_accrual",
          account_id: @account_id
        }
      )

      InterestAccrual.find_or_create_by!(posting_batch_id: batch.id) do |accrual|
        accrual.account_id = @account_id
        accrual.accrual_date = @accrual_date
        accrual.amount_cents = @amount_cents
        accrual.status = Bankcore::Enums::STATUS_POSTED
      end

      batch
    end
  end

  private

  def resolve_interest_expense_gl_account!
    account = Account.includes(:account_product).find(@account_id)
    gl_account = account.account_product&.resolved_interest_expense_gl_account
    raise ArgumentError, "No interest expense GL configured for account product" unless gl_account

    gl_account
  end
end
