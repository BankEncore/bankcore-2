# frozen_string_literal: true

class AddIdempotencyFingerprintToPostingBatches < ActiveRecord::Migration[8.1]
  def change
    add_column :posting_batches, :idempotency_fingerprint, :string
    add_column :posting_batches, :idempotency_payload_json, :text
  end
end
