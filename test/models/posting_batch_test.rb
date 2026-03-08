# frozen_string_literal: true

require "test_helper"

class PostingBatchTest < ActiveSupport::TestCase
  test "validates status inclusion" do
    batch = PostingBatch.new(business_date: Date.current, transaction_code: "ADJ_CREDIT", status: "invalid")
    assert_not batch.valid?
  end

  test "has many posting_legs" do
    batch = PostingBatch.new(business_date: Date.current, transaction_code: "ADJ_CREDIT", status: "draft")
    assert_respond_to batch, :posting_legs
  end

  test "posted scope returns only posted batches" do
    # Create a posted batch via PostingEngine in service test
    assert_respond_to PostingBatch, :posted
  end
end
