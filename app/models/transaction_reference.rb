# frozen_string_literal: true

class TransactionReference < ApplicationRecord
  REFERENCE_TYPE_REFERENCE_NUMBER = "reference_number"
  REFERENCE_TYPE_EXTERNAL_REFERENCE = "external_reference"
  REFERENCE_TYPE_IDEMPOTENCY_KEY = "idempotency_key"
  REFERENCE_TYPE_ACH_TRACE_NUMBER = "ach_trace_number"
  REFERENCE_TYPE_ACH_EFFECTIVE_DATE = "ach_effective_date"
  REFERENCE_TYPE_ACH_BATCH_REFERENCE = "ach_batch_reference"
  REFERENCE_TYPE_ACH_COMPANY_NAME = "ach_company_name"
  REFERENCE_TYPE_ACH_IDENTIFICATION_NUMBER = "ach_identification_number"
  REFERENCE_TYPE_CHECK_NUMBER = "check_number"
  REFERENCE_TYPE_INSTRUMENT_NUMBER = "instrument_number"
  REFERENCE_TYPE_AUTHORIZATION_REFERENCE = "authorization_reference"
  REFERENCE_TYPE_AUTHORIZATION_SOURCE = "authorization_source"

  belongs_to :operational_transaction, class_name: "BankingTransaction", foreign_key: :transaction_id

  validates :reference_type, presence: true
  validates :reference_value, presence: true
  validates :reference_value, uniqueness: { scope: [ :transaction_id, :reference_type ] }
end
