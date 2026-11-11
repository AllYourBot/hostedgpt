# A remote MCP server whose tools the user's assistants can call.
class Connector < ApplicationRecord
  include Tools

  belongs_to :user

  encrypts :token
  normalizes :url, with: -> url { url.strip }
  normalizes :token, with: -> token { token.strip }

  scope :ordered, -> { order(:name) }

  validates :name, :url, presence: true
  validates :url, format: URI::DEFAULT_PARSER.make_regexp(%w[http https]), if: -> { url.present? }
end
