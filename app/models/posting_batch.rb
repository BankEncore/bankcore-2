# frozen_string_literal: true

class PostingBatch < ApplicationRecord
  include Bankcore::Enums
  include PostedRecordImmutable

  belongs_to :operational_transaction, class_name: "BankingTransaction", optional: true
  belongs_to :reversal_of_batch, class_name: "PostingBatch", optional: true
  has_many :posting_legs, dependent: :destroy
  has_many :journal_entries, dependent: :destroy
  has_many :fee_assessments
  has_many :interest_accruals
  has_many :interest_posting_applications, dependent: :restrict_with_error
  has_one :reversal_batch, class_name: "PostingBatch", foreign_key: :reversal_of_batch_id

  validates :status, presence: true, inclusion: { in: Bankcore::Enums::POSTING_STATUSES }
  validates :business_date, presence: true
  validates :transaction_code, presence: true
  validates :posting_reference, uniqueness: true, allow_nil: true

  scope :posted, -> { where(status: Bankcore::Enums::STATUS_POSTED) }

  before_validation :assign_posting_reference, on: :create

  def posted_record_immutable?
    status == STATUS_POSTED
  end

  private

  def assign_posting_reference
    return if posting_reference.present?
    return unless status == STATUS_POSTED

    self.posting_reference = generate_posting_reference
  end

  def generate_posting_reference
    loop do
      candidate = "PB-#{Time.current.utc.strftime('%Y%m%d')}-#{SecureRandom.hex(6).upcase}"
      return candidate unless self.class.exists?(posting_reference: candidate)
    end
  end
end
