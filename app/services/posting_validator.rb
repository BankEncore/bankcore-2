# frozen_string_literal: true

class PostingValidator
  include Bankcore::Enums

  class ValidationError < StandardError; end
  class UnbalancedPostingError < ValidationError; end
  class InvalidTargetError < ValidationError; end
  class InvalidAmountError < ValidationError; end
  class BusinessDateClosedError < ValidationError; end

  def initialize(legs:, business_date:)
    @legs = legs
    @business_date = business_date
  end

  def validate!
    validate_positive_amounts!
    validate_targets!
    validate_balance!
    validate_business_date!
  end

  private

  def validate_positive_amounts!
    @legs.each do |leg|
      amount = leg[:amount_cents]
      raise InvalidAmountError, "Leg amounts must be positive (got #{amount})" if amount.blank? || amount <= 0
    end
  end

  def validate_balance!
    debits = @legs.select { |l| l[:leg_type] == LEG_TYPE_DEBIT }.sum { |l| l[:amount_cents] }
    credits = @legs.select { |l| l[:leg_type] == LEG_TYPE_CREDIT }.sum { |l| l[:amount_cents] }

    raise UnbalancedPostingError, "Debits (#{debits}) != Credits (#{credits})" unless debits == credits
  end

  def validate_targets!
    @legs.each do |leg|
      if leg[:ledger_scope] == LEDGER_SCOPE_ACCOUNT
        raise InvalidTargetError, "Account leg missing account_id" if leg[:account_id].blank?
      elsif leg[:ledger_scope] == LEDGER_SCOPE_GL
        raise InvalidTargetError, "GL leg missing gl_account_id" if leg[:gl_account_id].blank?
      end
    end
  end

  def validate_business_date!
    return if BusinessDateService.open?(@business_date)

    raise BusinessDateClosedError, "Business date #{@business_date} is not open for posting"
  end
end
