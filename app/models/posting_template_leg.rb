# frozen_string_literal: true

class PostingTemplateLeg < ApplicationRecord
  include Bankcore::Enums

  belongs_to :posting_template
  belongs_to :gl_account, optional: true

  validates :leg_type, presence: true, inclusion: { in: Bankcore::Enums::LEG_TYPES }
  validates :account_source, inclusion: { in: Bankcore::Enums::ACCOUNT_SOURCES }, allow_nil: true
  validate :has_target

  private

  def has_target
    return if gl_account_id.present? || account_source.present?

    errors.add(:base, "Leg must have gl_account or account_source")
  end
end
