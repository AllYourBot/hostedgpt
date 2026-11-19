class MessagesController < ApplicationController
  include ActiveStorage::SetCurrent
  include HasConversationStarter

  before_action :set_version,               only: [:index, :update]
  before_action :set_conversation,          only: [:index]
  before_action :set_assistant,             only: [:index, :new, :edit, :create]
  before_action :set_message,               only: [:show, :edit, :update, :bookmark, :unbookmark]
  before_action :set_nav_assistants,        only: [:index, :new]
  before_action :set_conversation_starters, only: [:new]

  def index
    if @version.blank?
      version = @conversation.messages.order(:created_at).last&.version
      if version
        redirect_to conversation_messages_path(params[:conversation_id], version: version), status: :see_other
      end
    end

    @messages = @conversation.messages.for_conversation_version(@version).preload(:bookmarks)
    @new_message = @assistant.messages.new(conversation: @conversation)
    @streaming_message = Message.where(
      content_text: [nil, ""],
      content_tool_calls: nil,
      cancelled_at: nil
    ).find_by(id: @conversation.last_assistant_message_id)
  end

  def show
  end

  def new
    @new_message = @assistant.messages.new
  end

  def edit
    @new_message = @assistant.messages.new
  end

  def create
    @message = @assistant.messages.new(message_params)

    if @message.save
      after_create_assistant_reply = @message.conversation.latest_message_for_version(@message.version)
      GetNextAIMessageJob.perform_later(Current.user.id, after_create_assistant_reply.id, @assistant.id)
      redirect_to conversation_messages_path(@message.conversation, version: @message.version), status: :see_other
    else
      # what's the right flow for a failed message create? it's not this, but hacking it so tests pass until we have a plan
      set_nav_assistants
      @new_message = @assistant.messages.new

      render :new, status: :unprocessable_content
    end
  end

  def update
    if @message.update(message_params)
      redirect_to conversation_messages_path(@message.conversation, version: @version || @message.version), status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def bookmark
    @message.bookmark!(Current.user)
    render_message_bookmark
  end

  def unbookmark
    # Page-context forms mark themselves with from_bookmarks: their entry element is
    # identified before the row is destroyed so the response can remove it in place
    # (KTD4's contract, shared with ConversationsController). Sidebar-context unbookmarks
    # re-render the row's own button, mirroring bookmark.
    entry = Current.user.bookmarks.find_by(bookmarkable: @message) if params[:from_bookmarks]
    @message.unbookmark!(Current.user)

    respond_to do |format|
      format.turbo_stream do
        if params[:from_bookmarks]
          streams = []
          streams << turbo_stream.remove(helpers.dom_id(entry)) if entry
          streams << nav_refresh_stream
          render turbo_stream: streams
        else
          render_message_bookmark
        end
      end
      format.html { head :no_content }
    end
  end

  private

  def set_version
    @version = params[:version].presence&.to_i
  end

  def set_conversation
    @conversation = Current.user.conversations.find(params[:conversation_id])
  end

  def set_assistant
    @assistant = Current.user.assistants_including_deleted.find_by(id: params[:assistant_id])
    @assistant ||= @conversation.latest_message_for_version(@version)&.assistant
    @assistant ||= @conversation.assistant
  end

  def set_message
    @message = Message.find(params[:id])
    redirect_to root_url, status: :unauthorized if @message.conversation.user != Current.user
  end

  # Message bookmarks answer with one stream — the row's own bookmark button — since bookmarks
  # are per-message state with no section to refresh. Plain requests still answer 204.
  def render_message_bookmark
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update("#{helpers.dom_id(@message)}-bookmark", partial: "messages/message_toggle_button", locals: {message: @message})
      end
      format.html { head :no_content }
    end
  end

  # The /bookmarks page's unbookmark forms refresh the sidebar's nav frame along with their
  # entry removal, so its bookmark icons re-render with current state. Same computation the
  # conversations controller's render_sidebar does; duplicated here because the message
  # controller has no other reason to know about the sidebar.
  def nav_refresh_stream
    @query = params[:query]
    @nav_conversations = Conversation.grouped_by_increasing_time_interval_for_user(Current.user, @query)
    turbo_stream.update("nav-conversations", partial: "conversations/nav", locals: {autofocus: false})
  end

  def set_nav_assistants
    @nav_assistants = Current.user.assistants.ordered
  end

  def message_params
    modified_params = params.require(:message).permit(
      :conversation_id,
      :content_text,
      :assistant_id,
      :index,
      :version,
      :role,
      :cancelled_at,
      :branched,
      :branched_from_version,
      :input_token_count,
      :output_token_count,
      :spoken,
      documents_attributes: [:file]
    )
    if modified_params.has_key?(:content_text) && modified_params[:content_text].blank?
      modified_params[:content_text] = nil # nil and "" have different meanings
    end
    modified_params
  end
end
