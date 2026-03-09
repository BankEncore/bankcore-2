# frozen_string_literal: true

module TransactionEntry
  module Policies
    class BasePolicy
      attr_reader :request

      def initialize(request)
        @request = request
      end

      def validate!
        require_transaction_code!
        validate_business_date!
        self
      end

      def resolved_amount_cents
        request.amount_cents
      end

      def preview_context_rows
        []
      end

      def preview_metadata
        request.preview_metadata
      end

      def post_attributes
        {
          transaction_code: request.transaction_code,
          account_id: request.account_id,
          source_account_id: request.source_account_id,
          destination_account_id: request.destination_account_id,
          amount_cents: resolved_amount_cents,
          business_date: request.business_date,
          memo: request.memo,
          reason_text: request.reason_text,
          reference_number: request.reference_number,
          external_reference: request.external_reference,
          idempotency_key: request.idempotency_key,
          created_by_id: request.created_by_id,
          gl_account_id: request.gl_account_id
        }.compact
      end

      def preview_attributes
        post_attributes.except(:created_by_id, :idempotency_key)
      end

      protected

      def require_transaction_code!
        raise ValidationError, "Transaction code is required" if request.transaction_code.blank?
      end

      def validate_business_date!
        return if BusinessDateService.open?(request.business_date)

        raise ValidationError, "Business date #{request.business_date} is not open for posting"
      end

      def require_field!(field_name, message = nil)
        return if request.public_send(field_name).present?

        raise ValidationError, message || "#{field_name.to_s.humanize} is required"
      end

      def require_one_of!(*field_names)
        return if field_names.any? { |field_name| request.public_send(field_name).present? }

        joined_names = field_names.map { |field_name| field_name.to_s.humanize.downcase }.join(" or ")
        raise ValidationError, "#{joined_names} is required"
      end

      def validate_positive_amount!
        raise ValidationError, "Amount is required" if request.amount_cents.blank?
        raise ValidationError, "Amount must be positive" if request.amount_cents <= 0
      end

      def active_account!(account_id)
        account = Account.find_by(id: account_id)
        raise ValidationError, "Account is required" if account.nil?
        raise ValidationError, "Account #{account.account_number} is not active" unless account.status == Bankcore::Enums::STATUS_ACTIVE

        account
      end

      def active_fee_type!
        fee_type = FeeType.find_by(id: request.fee_type_id)
        raise ValidationError, "Fee type is required" if fee_type.nil?
        raise ValidationError, "Fee type #{fee_type.code} is not active" unless fee_type.status == Bankcore::Enums::STATUS_ACTIVE

        fee_type
      end

      def active_interest_rule!(account)
        interest_rule = InterestRule
          .where(account_product_id: account.account_product_id)
          .active_on(request.business_date)
          .ordered
          .first

        raise ValidationError, "No active interest rule for the selected account product" unless interest_rule

        interest_rule
      end
    end
  end
end
