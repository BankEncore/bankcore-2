# frozen_string_literal: true

class ProductGlResolver
  PRODUCT_GL_NUMBERS = {
    "dda" => "2110",
    "now" => "2120",
    "savings" => "2130",
    "cd" => "2130"
  }.freeze

  def self.resolve_account_gl(account)
    new(account).resolve_account_gl
  end

  def initialize(account)
    @account = account
  end

  def resolve_account_gl
    return nil unless @account

    if loan_product?
      @account.account_product&.asset_gl_account
    else
      @account.account_product&.liability_gl_account || fallback_liability_gl
    end
  end

  private

  def loan_product?
    @account.account_product&.product_family == "loan" || @account.account_type == "loan"
  end

  def fallback_liability_gl
    gl_number = PRODUCT_GL_NUMBERS[@account.account_type]
    return nil unless gl_number

    GlAccount.find_by(gl_number: gl_number)
  end
end
