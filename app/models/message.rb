class Message < ApplicationRecord
  belongs_to :conversation
  belongs_to :content_document, class_name: "Document", optional: true
  belongs_to :run, optional: true

  has_many :documents, dependent: :destroy

  enum role: %w[ user assistant ].index_by(&:to_sym)

  validates :run, presence: true, if: ->{ assistant? }
end
