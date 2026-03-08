# frozen_string_literal: true

module Bankcore
  module Enums
    # Status values for parties, accounts, branches, etc.
    STATUS_ACTIVE = "active"
    STATUS_INACTIVE = "inactive"
    STATUS_CLOSED = "closed"
    STATUS_PENDING = "pending"
    STATUS_DRAFT = "draft"
    STATUS_VALIDATED = "validated"
    STATUS_POSTED = "posted"
    STATUS_REVERSED = "reversed"

    STATUSES = [
      STATUS_ACTIVE,
      STATUS_INACTIVE,
      STATUS_CLOSED,
      STATUS_PENDING,
      STATUS_DRAFT,
      STATUS_VALIDATED,
      STATUS_POSTED,
      STATUS_REVERSED
    ].freeze

    # Posting batch / transaction statuses
    POSTING_STATUSES = [ STATUS_DRAFT, STATUS_VALIDATED, STATUS_POSTED, STATUS_REVERSED ].freeze

    # Leg types for posting_legs
    LEG_TYPE_DEBIT = "debit"
    LEG_TYPE_CREDIT = "credit"
    LEG_TYPES = [ LEG_TYPE_DEBIT, LEG_TYPE_CREDIT ].freeze

    # Ledger scope: where the leg posts
    LEDGER_SCOPE_ACCOUNT = "account"
    LEDGER_SCOPE_GL = "gl"
    LEDGER_SCOPES = [ LEDGER_SCOPE_ACCOUNT, LEDGER_SCOPE_GL ].freeze

    # Account source for posting template legs
    ACCOUNT_SOURCE_CUSTOMER = "customer_account"
    ACCOUNT_SOURCE_SOURCE = "source_account"
    ACCOUNT_SOURCE_DESTINATION = "destination_account"
    ACCOUNT_SOURCE_FIXED_GL = "fixed_gl"
    ACCOUNT_SOURCE_PRODUCT_GL = "product_gl"
    ACCOUNT_SOURCES = [
      ACCOUNT_SOURCE_CUSTOMER,
      ACCOUNT_SOURCE_SOURCE,
      ACCOUNT_SOURCE_DESTINATION,
      ACCOUNT_SOURCE_FIXED_GL,
      ACCOUNT_SOURCE_PRODUCT_GL
    ].freeze

    # GL account categories
    GL_CATEGORY_ASSET = "asset"
    GL_CATEGORY_LIABILITY = "liability"
    GL_CATEGORY_EQUITY = "equity"
    GL_CATEGORY_INCOME = "income"
    GL_CATEGORY_EXPENSE = "expense"
    GL_CATEGORIES = [
      GL_CATEGORY_ASSET,
      GL_CATEGORY_LIABILITY,
      GL_CATEGORY_EQUITY,
      GL_CATEGORY_INCOME,
      GL_CATEGORY_EXPENSE
    ].freeze

    # Normal balance for GL accounts
    NORMAL_BALANCE_DEBIT = "debit"
    NORMAL_BALANCE_CREDIT = "credit"
    NORMAL_BALANCES = [ NORMAL_BALANCE_DEBIT, NORMAL_BALANCE_CREDIT ].freeze

    # Business date status
    BUSINESS_DATE_OPEN = "open"
    BUSINESS_DATE_CLOSED = "closed"
    BUSINESS_DATE_STATUSES = [ BUSINESS_DATE_OPEN, BUSINESS_DATE_CLOSED ].freeze

    # Party types
    PARTY_TYPE_PERSON = "person"
    PARTY_TYPE_ORGANIZATION = "organization"
    PARTY_TYPES = [ PARTY_TYPE_PERSON, PARTY_TYPE_ORGANIZATION ].freeze

    # Override request status
    OVERRIDE_STATUS_PENDING = "pending"
    OVERRIDE_STATUS_APPROVED = "approved"
    OVERRIDE_STATUS_DENIED = "denied"
    OVERRIDE_STATUS_EXPIRED = "expired"
    OVERRIDE_STATUS_USED = "used"
    OVERRIDE_STATUSES = [
      OVERRIDE_STATUS_PENDING,
      OVERRIDE_STATUS_APPROVED,
      OVERRIDE_STATUS_DENIED,
      OVERRIDE_STATUS_EXPIRED,
      OVERRIDE_STATUS_USED
    ].freeze

    # Override request types
    OVERRIDE_TYPE_REVERSAL = "reversal"
    OVERRIDE_TYPE_HIGH_VALUE_ADJUSTMENT = "high_value_adjustment"
    OVERRIDE_TYPE_BACKDATED_ACTIVITY = "backdated_activity"
    OVERRIDE_TYPES = [
      OVERRIDE_TYPE_REVERSAL,
      OVERRIDE_TYPE_HIGH_VALUE_ADJUSTMENT,
      OVERRIDE_TYPE_BACKDATED_ACTIVITY
    ].freeze

    # Account hold types
    HOLD_TYPE_MANUAL = "manual"
    HOLD_TYPE_LEGAL = "legal"
    HOLD_TYPE_REGULATORY = "regulatory"
    HOLD_TYPES = [ HOLD_TYPE_MANUAL, HOLD_TYPE_LEGAL, HOLD_TYPE_REGULATORY ].freeze

    # Account hold status
    HOLD_STATUS_ACTIVE = "active"
    HOLD_STATUS_RELEASED = "released"
    HOLD_STATUSES = [ HOLD_STATUS_ACTIVE, HOLD_STATUS_RELEASED ].freeze
  end
end
