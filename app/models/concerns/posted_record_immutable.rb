# frozen_string_literal: true

module PostedRecordImmutable
  extend ActiveSupport::Concern

  included do
    before_update :prevent_posted_record_mutation
    before_destroy :prevent_posted_record_destruction
  end

  private

  def prevent_posted_record_mutation
    prevent_posted_record_change("cannot be updated once posted") if posted_record_immutable?
  end

  def prevent_posted_record_destruction
    prevent_posted_record_change("cannot be deleted once posted") if posted_record_immutable?
  end

  def prevent_posted_record_change(message)
    errors.add(:base, message)
    throw(:abort)
  end
end
