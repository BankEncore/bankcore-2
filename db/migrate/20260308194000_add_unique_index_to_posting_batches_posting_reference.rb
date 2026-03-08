# frozen_string_literal: true

class AddUniqueIndexToPostingBatchesPostingReference < ActiveRecord::Migration[8.1]
  def change
    add_index :posting_batches, :posting_reference, unique: true
  end
end
