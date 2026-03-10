# frozen_string_literal: true

class CreateBankDraftSequences < ActiveRecord::Migration[8.1]
  def change
    create_table :bank_draft_sequences do |t|
      t.references :branch, null: false, foreign_key: true
      t.string :instrument_type, null: false
      t.integer :last_number, null: false, default: 0

      t.timestamps
    end

    add_index :bank_draft_sequences, [:branch_id, :instrument_type],
      unique: true,
      name: "index_bank_draft_sequences_on_branch_and_type"
  end
end
