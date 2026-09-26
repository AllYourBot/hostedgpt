class Conversation < ApplicationRecord
  include Version
  include Reorderable
  include Pinnable
  include Bookmarkable
  include Reactable

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
  # (pinned_nav_for_user); this is the unpinned relation underneath it, in recency order
  # (updated_at desc) so a reply bubbles its conversation to the top. Pins carry the only hand
  # order — position is ignored here.
  def self.nav_for_user(user, query = nil)
    return user.conversations.preload(:assistant).matching_query(query) if query.present?

    user.conversations.preload(:assistant).unpinned_for(user).order(updated_at: :desc, id: :desc)
  end

  # The sidebar's pinned section for the user, in hand order (conversations.position). Hidden
  # during search so the filtered list stays flat with the drag-disabled guard.
  def self.pinned_nav_for_user(user, query = nil)
    return none if query.present?

    user.conversations.preload(:assistant).pinned_for(user)
  end

  # Builds a hash of date interval keys and the unpinned conversations (pins live in their own
  # section above) active in each interval, newest interval first, recency order inside each
  # group. Search bypasses grouping — it keeps the existing flat filtered list. Empty intervals
  # are removed from the hash.
  #
  # {
  #  "Today" => relation,
  #  "Yesterday" => relation,
  #  "This Week" => relation,
  #  "This Month" => relation,
  #  "Last Month" => relation,
  #  "Older" => relation
  # }
  def self.grouped_by_increasing_time_interval_for_user(user)
    nav_conversations = nav_for_user(user)

    # NOTE: These keys intentionally remain static for test stability. UI layers may translate.
    keys = ["Today", "Yesterday", "This Week", "This Month", "Last Month", "Older"]
    values = [
      nil,
      Date.current.beginning_of_day,
      (Date.current - 1.day).beginning_of_day,
      (Date.current - 1.week).beginning_of_day,
      (Date.current - 1.month).beginning_of_day,
      (Date.current - 2.months).beginning_of_day,
      nil
    ].each_cons(2).map do |range_start, range_end|
      range = case
      when range_start.nil?
        range_end..
      when range_end.nil?
        ..range_start
      else
        range_end..range_start
      end

      nav_conversations.where(updated_at: range)
    end

    keys.zip(values)
      .to_h
      .delete_if { |_, v| v.empty? }
  end

  # The bookmarks view: every bookmarked conversation for the user in display order, optionally
  # narrowed by the search query. Bookmarks never touch position, so toggles leave this order
  # alone. Pins are not split out here — a pinned conversation still appears in this list. The
  # search narrows first through the shared matching_query, then membership applies: the other
  # order raises a structurally-incompatible `or` inside matching_query.
  def self.bookmarked_nav_for_user(user, query = nil)
    scope = user.conversations.preload(:assistant).ordered
    scope = scope.matching_query(query) if query.present?
    scope.bookmarked_for(user)
  end

  # The reactions view: every conversation the user reacted to — directly or on one of its
  # messages — newest touching reaction first. Reactions never touch position, so this ignores
  # display order entirely. Pins are not split out here — a pinned conversation still appears
  # in this list. The search narrows first through the shared matching_query, then membership
  # applies: the other order raises a structurally-incompatible `or` inside matching_query.
  def self.reacted_nav_for_user(user, query = nil)
    scope = user.conversations
    scope = scope.matching_query(query) if query.present?
    candidate_ids = scope.ids

    latest_by_conversation = Reaction.where(user: user, reactable_type: "Conversation", reactable_id: candidate_ids)
      .group(:reactable_id).maximum(:created_at)
    Reaction.where(user: user, reactable_type: "Message")
      .joins("INNER JOIN messages ON messages.id = reactions.reactable_id")
      .where(messages: { conversation_id: candidate_ids })
      .group("messages.conversation_id").maximum(:created_at)
      .each { |id, at| latest_by_conversation[id] = [latest_by_conversation[id], at].compact.max }

    return none if latest_by_conversation.empty?

    ordered_ids = latest_by_conversation.sort_by { |_, at| at }.reverse.map(&:first)
    user.conversations.preload(:assistant).where(id: ordered_ids).in_order_of(:id, ordered_ids)
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
