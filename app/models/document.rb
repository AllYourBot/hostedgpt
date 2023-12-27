class Document < ApplicationRecord
  belongs_to :user
  belongs_to :assistant, optional: true
  belongs_to :message, optional: true

  enum purpose: %w[fine-tune fine-tune-results assistants assistants_output].index_by(&:to_sym)

  validates :purpose, :filename, :bytes, presence: true
end
