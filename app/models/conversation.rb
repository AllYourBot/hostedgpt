class Conversation < ApplicationRecord
  include Version
  include Reorderable
  include Pinnable

  belongs_to :user
  belongs_to :assistant

  has_many :messages, dependent: :destroy
  has_many :runs, dependent: :destroy
  has_many :steps, dependent: :destroy
  belongs_to :last_assistant_message, class_name: "Message", inverse_of: :conversation, optional: true

  before_create :generate_share_token
  after_touch :set_title_async, if: -> { title.blank? && messages.count >= 2 }

  broadcasts_refreshes

  # The sidebar's search: conversations whose title, or any message's content, matches the query.
  # Wildcards the user types are literal characters, not patterns — a search for "%" means a
  # literal percent sign. DISTINCT because a conversation matching on both would otherwise repeat
  # once per matching message.
  scope :matching_query, ->(query) {
    pattern = "%#{ActiveRecord::Base.sanitize_sql_like(query)}%"
    joins(:messages).ordered.where("messages.content_text ILIKE ?", pattern).
      or(ordered.where("title ILIKE ?", pattern)).
      select("DISTINCT conversations.*")
  }

  # The sidebar's conversation list: every conversation for the user in display order, optionally
  # narrowed by the search query. The blank case bypasses the join on purpose — an empty search
  # must still return conversations that have no messages yet. Rows render their assistant, so it
  # rides along in one extra query instead of one per row. Pins live in their own section above
  # (pinned_nav_for_user); this is the unpinned relation underneath it.
  def self.nav_for_user(user, query = nil)
    return user.conversations.preload(:assistant).matching_query(query) if query.present?

    user.conversations.preload(:assistant).unpinned_for(user).ordered
  end

  # The sidebar's pinned section for the user, in hand order (conversations.position). Hidden
  # during search so the filtered list stays flat with the drag-disabled guard.
  def self.pinned_nav_for_user(user, query = nil)
    return none if query.present?

    user.conversations.preload(:assistant).pinned_for(user)
  end

  def generate_shareable_url(request)
    ensure_share_token!
    Rails.application.routes.url_helpers.public_conversation_url(share_token, host: request.host_with_port)
  end

  def ensure_share_token!
    if share_token.blank?
      update_column(:share_token, SecureRandom.urlsafe_base64(32))
    end
    share_token
  end

  private

  def generate_share_token
    self.share_token = SecureRandom.urlsafe_base64(32)
  end

  def set_title_async
    AutotitleConversationJob.perform_later(id)
  end
end
