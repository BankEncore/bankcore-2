# frozen_string_literal: true

module TransactionEntry
  class Dispatcher
    def self.preview!(request:)
      new(request: request).preview!
    end

    def self.post!(request:)
      new(request: request).post!
    end

    def initialize(request:)
      @request = request
    end

    def preview!
      current_policy.validate!
      ensure_manual_shell_support!

      {
        legs: PostingEngine.preview!(**current_policy.preview_attributes),
        amount_cents: current_policy.resolved_amount_cents,
        metadata: current_policy.preview_metadata,
        context_rows: current_policy.preview_context_rows
      }
    end

    def post!
      current_policy.validate!

      case @request.family
      when :adjustment, :transfer
        PostingEngine.post!(**current_policy.post_attributes)
      when :fee
        FeePostingService.assess!(**current_policy.fee_service_attributes)
      when :ach
        AchEntryService.post!(**current_policy.ach_service_attributes)
      when :check
        CheckEntryService.post!(**current_policy.check_service_attributes)
      else
        raise UnsupportedTransactionError, "#{@request.transaction_code} must use its dedicated workflow"
      end
    end

    private

    def current_policy
      @current_policy ||= PolicyRegistry.build(@request)
    end

    def ensure_manual_shell_support!
      return if @request.manual_entry_code?

      raise UnsupportedTransactionError, "#{@request.transaction_code} must use its dedicated workflow"
    end
  end
end
