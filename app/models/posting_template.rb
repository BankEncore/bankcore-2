class PostingTemplate < ApplicationRecord
  belongs_to :transaction_code
  has_many :posting_template_legs, dependent: :destroy
end
