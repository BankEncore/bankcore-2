# frozen_string_literal: true

module TransactionEntry
  class PolicyRegistry
    def self.build(request)
      klass = case request.family
      when :adjustment
        TransactionEntry::Policies::AdjustmentPolicy
      when :transfer
        TransactionEntry::Policies::TransferPolicy
      when :fee
        TransactionEntry::Policies::FeePolicy
      when :interest_accrual
        TransactionEntry::Policies::InterestAccrualPolicy
      when :interest_post
        TransactionEntry::Policies::InterestPostPolicy
      when :ach
        TransactionEntry::Policies::AchPolicy
      when :check
        TransactionEntry::Policies::CheckPolicy
      when :reversal
        TransactionEntry::Policies::ReversalPolicy
      else
        raise UnsupportedTransactionError, "Unsupported transaction code #{request.transaction_code.inspect}"
      end

      klass.new(request)
    end
  end
end
