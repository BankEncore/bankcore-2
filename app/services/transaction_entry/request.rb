# frozen_string_literal: true

module TransactionEntry
  class Request
    MANUAL_ENTRY_CODES = %w[
      ADJ_CREDIT
      ADJ_DEBIT
      XFER_INTERNAL
      FEE_POST
      ACH_CREDIT
      ACH_DEBIT
    ].freeze

    attr_reader :transaction_code, :account_id, :source_account_id, :destination_account_id,
      :amount, :amount_cents, :memo, :reason_text, :reference_number, :external_reference,
      :idempotency_key, :created_by_id, :business_date, :fee_type_id, :fee_rule_id,
      :original_fee_assessment_id, :interest_rule_id, :accrual_date, :posting_cycle,
      :ach_trace_number, :ach_effective_date, :ach_batch_reference,
      :authorization_reference, :authorization_source, :override_request_id,
      :reversal_target_transaction_id, :gl_account_id

    def self.from_form(raw_params:, created_by_id:, business_date: nil)
      new(
        transaction_code: normalize_string(raw_params[:transaction_code]),
        account_id: normalize_integer(raw_params[:account_id]),
        source_account_id: normalize_integer(raw_params[:source_account_id]),
        destination_account_id: normalize_integer(raw_params[:destination_account_id]),
        amount: normalize_string(raw_params[:amount]),
        amount_cents: normalize_amount(raw_params[:amount]),
        memo: normalize_string(raw_params[:memo]),
        reason_text: normalize_string(raw_params[:reason_text]),
        reference_number: normalize_string(raw_params[:reference_number]),
        external_reference: normalize_string(raw_params[:external_reference]),
        idempotency_key: normalize_string(raw_params[:idempotency_key]),
        created_by_id: created_by_id,
        business_date: business_date || BusinessDateService.current,
        fee_type_id: normalize_integer(raw_params[:fee_type_id]),
        fee_rule_id: normalize_integer(raw_params[:fee_rule_id]),
        original_fee_assessment_id: normalize_integer(raw_params[:original_fee_assessment_id]),
        interest_rule_id: normalize_integer(raw_params[:interest_rule_id]),
        accrual_date: normalize_date(raw_params[:accrual_date]),
        posting_cycle: normalize_string(raw_params[:posting_cycle]),
        ach_trace_number: normalize_string(raw_params[:ach_trace_number]),
        ach_effective_date: normalize_date(raw_params[:ach_effective_date]),
        ach_batch_reference: normalize_string(raw_params[:ach_batch_reference]),
        authorization_reference: normalize_string(raw_params[:authorization_reference]),
        authorization_source: normalize_string(raw_params[:authorization_source]),
        override_request_id: normalize_integer(raw_params[:override_request_id]),
        reversal_target_transaction_id: normalize_integer(raw_params[:reversal_target_transaction_id]),
        gl_account_id: normalize_integer(raw_params[:gl_account_id])
      )
    end

    def self.normalize_string(value)
      value.respond_to?(:strip) ? value.strip.presence : value.presence
    end

    def self.normalize_integer(value)
      return nil if normalize_string(value).blank?

      value.to_i
    end

    def self.normalize_amount(value)
      return nil if normalize_string(value).blank?

      (value.to_d * 100).round
    end

    def self.normalize_date(value)
      return nil if normalize_string(value).blank?

      value.to_date
    rescue ArgumentError
      nil
    end

    def initialize(**attrs)
      attrs.each do |key, value|
        instance_variable_set("@#{key}", value)
      end
    end

    def family
      case transaction_code
      when "ADJ_CREDIT", "ADJ_DEBIT"
        :adjustment
      when "XFER_INTERNAL"
        :transfer
      when "FEE_POST"
        :fee
      when "INT_ACCRUAL"
        :interest_accrual
      when "INT_POST"
        :interest_post
      when "ACH_CREDIT", "ACH_DEBIT"
        :ach
      when /\A.*_REVERSAL\z/
        :reversal
      else
        :unknown
      end
    end

    def manual_entry_code?
      MANUAL_ENTRY_CODES.include?(transaction_code)
    end

    def to_form_params
      {
        transaction_code: transaction_code,
        account_id: account_id,
        source_account_id: source_account_id,
        destination_account_id: destination_account_id,
        amount: amount,
        memo: memo,
        reason_text: reason_text,
        reference_number: reference_number,
        external_reference: external_reference,
        idempotency_key: idempotency_key,
        fee_type_id: fee_type_id,
        fee_rule_id: fee_rule_id,
        original_fee_assessment_id: original_fee_assessment_id,
        interest_rule_id: interest_rule_id,
        accrual_date: accrual_date&.iso8601,
        posting_cycle: posting_cycle,
        ach_trace_number: ach_trace_number,
        ach_effective_date: ach_effective_date&.iso8601,
        ach_batch_reference: ach_batch_reference,
        authorization_reference: authorization_reference,
        authorization_source: authorization_source,
        override_request_id: override_request_id,
        reversal_target_transaction_id: reversal_target_transaction_id
      }.compact
    end

    def preview_metadata
      {
        memo: memo,
        reason_text: reason_text,
        reference_number: reference_number,
        external_reference: external_reference,
        idempotency_key: idempotency_key
      }.compact
    end
  end
end
