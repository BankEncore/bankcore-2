# frozen_string_literal: true

module TransactionEntry
  module Policies
    class FeePolicy < BasePolicy
      def validate!
        super
        active_account!
        active_fee_type!
        validate_amount_override!
        resolve_fee_rule!
        self
      end

      def resolved_amount_cents
        request.amount_cents || resolved_fee_rule.amount_cents_for_assessment
      end

      def preview_context_rows
        [
          [ "Fee Type", active_fee_type!.code ],
          [ "Fee Rule", resolved_fee_rule.id.to_s ],
          [ "Amount Source", request.amount_cents.present? ? "Manual override" : "Fee rule / fee type default" ]
        ]
      end

      def preview_attributes
        super.merge(gl_account_id: resolved_gl_account_id)
      end

      def fee_service_attributes
        {
          account_id: active_account!.id,
          fee_type_id: active_fee_type!.id,
          fee_rule_id: resolved_fee_rule.id,
          amount_cents: resolved_amount_cents,
          gl_account_id: resolved_gl_account_id,
          business_date: request.business_date,
          idempotency_key: request.idempotency_key
        }
      end

      private

      def validate_amount_override!
        return if request.amount_cents.blank?
        raise ValidationError, "Fee amount override must be positive" if request.amount_cents <= 0
      end

      def active_account!
        @active_account ||= super(request.account_id)
      end

      def active_fee_type!
        @active_fee_type ||= super
      end

      def resolve_fee_rule!
        @resolved_fee_rule ||= FeeRule
          .where(account_product_id: active_account!.account_product_id, fee_type_id: active_fee_type!.id)
          .active_on(request.business_date)
          .ordered
          .first

        raise ValidationError, "No active fee rule for #{active_fee_type!.code} on the selected account product" unless @resolved_fee_rule

        @resolved_fee_rule
      end

      def resolved_fee_rule
        @resolved_fee_rule || resolve_fee_rule!
      end

      def resolved_gl_account_id
        resolved_fee_rule.gl_account_id_for_posting
      end
    end
  end
end
