class Conversation < ApplicationRecord
  include Version, Bookmarkable

  belongs_to :user
  belongs_to :assistant

  has_many :messages, dependent: :destroy
  has_many :runs, dependent: :destroy
  has_many :steps, dependent: :destroy
  belongs_to :last_assistant_message, class_name: "Message", inverse_of: :conversation, optional: true

  before_create :generate_share_token
  after_touch :set_title_async, if: -> { title.blank? && messages.count >= 2 }

  scope :ordered, -> { order(updated_at: :desc, id: :desc) }
  scope :pinned, -> { where.not(pin_position: nil).order(:pin_position, id: :desc) }

  broadcasts_refreshes

  # Builds a hash of date interval keys and queries which fetch the records for that internal.
  #
  # Empty intervals are removed from the hash.
  #
  # Pass exclude_pinned: true to leave pinned conversations out; the sidebar lists those in their own
  # section above these groups.
  #
  # {
  #  "Today" => relation,
  #  "Yesterday" => relation,
  #  "This Week" => relation,
  #  "This Month" => relation,
  #  "Last Month" => relation,
  #  "Older" => relation
  # }
  def self.grouped_by_increasing_time_interval_for_user(user, query = nil, exclude_pinned: false)
    if query.blank?
      nav_conversations = user.conversations.ordered.preload(:bookmarks, :assistant)
    else
      nav_conversations = user.conversations.joins(:messages).ordered.where("messages.content_text ILIKE ?", "%#{query}%").
        or(user.conversations.ordered.where("title ILIKE ?", "%#{query}%")).
        select("DISTINCT conversations.*").preload(:bookmarks, :assistant)
    end

    nav_conversations = nav_conversations.where(pin_position: nil) if exclude_pinned

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


  # Renumbers the pinned conversations in this collection to match the order of ids, which is how the
  # sidebar hands back a Pinned list the user has dragged into shape. Ids that are not pinned, or that
  # the collection does not contain, are simply ignored: a user-scoped relation cannot be talked into
  # reordering someone else's conversations, and a stale page cannot pin a conversation by dragging it.
  #
  # update_column skips timestamps on purpose, for the same reason pin! does.
  def self.reposition(ids)
    ids = ids.map(&:to_i)

    transaction do
      pinned.where(id: ids).each { it.update_column(:pin_position, ids.index(it.id)) }
    end
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

  def pinned? = pin_position.present?

  # A newly pinned conversation goes to the top of the pinned list, the same convention the assistants
  # list uses for a new assistant. Pinning one that is already pinned leaves it where it is.
  #
  # update_columns skips callbacks and timestamps on purpose: pinning is not activity in the
  # conversation, so it must not bump updated_at, which decides the time group it sits in.
  def pin!
    return if pinned?

    update_columns(pin_position: (user.conversations.minimum(:pin_position) || 0) - 1)
  end

  def unpin!
    update_columns(pin_position: nil)
  end

  # update_column skips updated_at, which orders the sidebar.
  def mark_unread! = update_column(:unread, true)

  def mark_read!
    return false unless unread?

    update_column(:unread, false)
  end

  private

  def generate_share_token
    self.share_token = SecureRandom.urlsafe_base64(32)
  end

  def set_title_async = AutotitleConversationJob.perform_later(id)
end
