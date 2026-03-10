# frozen_string_literal: true

module TransactionEntry
  module Policies
    class CheckPolicy < BasePolicy
      include Bankcore::Enums

      def validate!
        super
        account = active_account!(request.account_id)
        raise ValidationError, "Account is not eligible for check writing" unless account.check_writing_eligible?

        validate_positive_amount!
        require_field!(:check_number, "Check number is required")
        validate_no_duplicate_check!(account) unless override_provided?
        if override_provided?
          validate_override_matches!
        else
          validate_funds_and_overdraft!(account)
        end
        self
      end

      def preview_context_rows
        [
          [ "Check Number", request.check_number ]
        ]
      end

      def check_service_attributes
        post_attributes.merge(
          check_number: request.check_number,
          override_request_id: request.override_request_id
        ).compact
      end

      private

      def override_provided?
        request.override_request_id.present?
      end

      def validate_override_matches!
        override = override_request_for_check
        raise ValidationError, "Override request not found or not usable" unless override
        stored = override.context_json.present? ? JSON.parse(override.context_json) : {}
        stored = stored.with_indifferent_access
        raise ValidationError, "Override context does not match this request" unless
          stored["account_id"]&.to_i == request.account_id &&
          stored["amount_cents"]&.to_i == request.amount_cents &&
          stored["check_number"]&.to_s == request.check_number.to_s
      end

      def validate_no_duplicate_check!(account)
        return unless CheckItem.exists?(account_id: account.id, check_number: request.check_number, status: CheckItem::STATUS_POSTED)
        require_field!(:confirmation_number, "Duplicate check detected. Enter confirmation number to post.")
      end

      def validate_funds_and_overdraft!(account)
        available_cents = account.account_balances.pick(:available_balance_cents) || 0
        available_cents = 0 if available_cents.nil?
        return if request.amount_cents <= available_cents

        overdraft_policy = resolve_overdraft_policy(account)
        if overdraft_policy == "disallow"
          raise ValidationError, "Insufficient funds. Overdraft is not allowed for this account."
        end

        od_amount = request.amount_cents - available_cents
        if od_amount >= Bankcore::CHECK_OVERDRAFT_OVERRIDE_THRESHOLD_CENTS
          override = override_request_for_check
          unless override&.usable?
            raise CheckOverdraftOverrideRequiredError.new(
              "Check overdraft above #{ActiveSupport::NumberHelper.number_to_currency(Bankcore::CHECK_OVERDRAFT_OVERRIDE_THRESHOLD_CENTS / 100.0)} requires supervisor approval.",
              account_id: request.account_id,
              amount_cents: request.amount_cents,
              check_number: request.check_number
            )
          end
        end
      end

      def resolve_overdraft_policy(account)
        return account.deposit_account.overdraft_policy if account.deposit_account&.overdraft_policy.present?

        account.account_product&.allow_overdraft ? "allow" : "disallow"
      end

      def override_request_for_check
        return nil unless request.override_request_id.present?

        OverrideRequest.usable.find_by(id: request.override_request_id, request_type: Bankcore::Enums::OVERRIDE_TYPE_CHECK_OVERDRAFT)
      end
    end
  end
end
