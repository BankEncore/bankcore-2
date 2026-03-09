class AddUniqueIndexToPostingBatchesReversalOfBatchId < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key :posting_batches, :posting_batches, column: :reversal_of_batch_id
    remove_index :posting_batches, column: :reversal_of_batch_id, if_exists: true
    add_index :posting_batches, :reversal_of_batch_id, unique: true
    add_foreign_key :posting_batches, :posting_batches, column: :reversal_of_batch_id
  end
end
