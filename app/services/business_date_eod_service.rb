# frozen_string_literal: true

class BusinessDateEodService
  include Bankcore::Enums

  class EODValidationError < StandardError; end

  def self.run!
    new.run!
  end

  def run!
    current = BusinessDate.find_by(status: BUSINESS_DATE_OPEN)
    raise EODValidationError, "No open business date to close" unless current

    validate!(current)

    ActiveRecord::Base.transaction do
      current.update!(status: BUSINESS_DATE_CLOSED, closed_at: Time.current)

      next_date = current.business_date + 1
      next_bd = BusinessDate.find_or_initialize_by(business_date: next_date)
      next_bd.assign_attributes(status: BUSINESS_DATE_OPEN, opened_at: Time.current)
      next_bd.save!

      AuditEmissionService.emit!(
        event_type: AuditEmissionService::EVENT_BUSINESS_DATE_CLOSED,
        action: "close",
        target: current,
        business_date: current.business_date,
        metadata: { closed_date: current.business_date.to_s, opened_date: next_date.to_s }
      )

      AuditEmissionService.emit!(
        event_type: AuditEmissionService::EVENT_BUSINESS_DATE_OPENED,
        action: "open",
        target: next_bd,
        business_date: next_date,
        metadata: { opened_date: next_date.to_s, prior_date: current.business_date.to_s }
      )
    end

    true
  end

  private

  def validate!(current)
    pending = BankingTransaction.where(business_date: current.business_date)
      .where.not(status: [ STATUS_POSTED, STATUS_REVERSED ])

    return if pending.none?

    raise EODValidationError,
      "Cannot close: #{pending.count} transaction(s) not yet posted or reversed"
  end
end
