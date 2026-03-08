# frozen_string_literal: true

class GlAccountsController < ApplicationController
  def index
    @gl_accounts = GlAccount
      .where(status: Bankcore::Enums::STATUS_ACTIVE)
      .order(:gl_number)
  end
end
