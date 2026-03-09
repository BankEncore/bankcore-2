# frozen_string_literal: true

class InterestPostingApplication < ApplicationRecord
  belongs_to :interest_accrual
  belongs_to :posting_batch

  validates :posted_on, presence: true
end
