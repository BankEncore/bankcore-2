# frozen_string_literal: true

class FeePostingService
  include Bankcore::Enums

  def self.assess!(account_id:, fee_type_id:, amount_cents: nil, business_date: nil, idempotency_key: nil,
                   fee_rule_id: nil, gl_account_id: nil)
    new(
      account_id: account_id,
      fee_type_id: fee_type_id,
      amount_cents: amount_cents,
      business_date: business_date,
      idempotency_key: idempotency_key,
      fee_rule_id: fee_rule_id,
      gl_account_id: gl_account_id
    ).assess!
  end

  def initialize(account_id:, fee_type_id:, amount_cents: nil, business_date: nil, idempotency_key: nil,
                 fee_rule_id: nil, gl_account_id: nil)
    @account_id = account_id
    @fee_type_id = fee_type_id
    @amount_cents = amount_cents
    @business_date = business_date || BusinessDateService.current
    @idempotency_key = idempotency_key
    @fee_rule_id = fee_rule_id
    @gl_account_id = gl_account_id
  end

  def assess!
    fee_type = FeeType.find(@fee_type_id)
    amount = @amount_cents || fee_type.default_amount_cents
    posting_gl_account_id = @gl_account_id || fee_type.gl_account_id
    raise ArgumentError, "Amount must be positive" if amount.to_i <= 0

    ActiveRecord::Base.transaction do
      batch = PostingEngine.post!(
        transaction_code: "FEE_POST",
        account_id: @account_id,
        amount_cents: amount,
        business_date: @business_date,
        idempotency_key: @idempotency_key,
        gl_account_id: posting_gl_account_id,
        idempotency_context: {
          service: "fee_posting",
          fee_type_id: @fee_type_id,
          fee_rule_id: @fee_rule_id
        }
      )

      FeeAssessment.find_or_create_by!(posting_batch_id: batch.id) do |assessment|
        assessment.account_id = @account_id
        assessment.fee_type_id = @fee_type_id
        assessment.fee_rule_id = @fee_rule_id
        assessment.amount_cents = amount
        assessment.assessed_on = @business_date
        assessment.status = Bankcore::Enums::STATUS_POSTED
      end

      batch
    end
  end
end
