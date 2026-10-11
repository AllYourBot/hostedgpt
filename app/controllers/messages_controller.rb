class MessagesController < ApplicationController
  include ActiveStorage::SetCurrent
  include HasConversationStarter

  before_action :set_version,               only: [:index, :update]
  before_action :set_conversation,          only: [:index]
  before_action :set_assistant,             only: [:index, :new, :edit, :create]
  before_action :set_message,               only: [:show, :edit, :update, :react, :unreact, :pin, :unpin, :bookmark, :unbookmark]
  before_action :set_nav_assistants,        only: [:index, :new]
  before_action :set_nav_collections,       only: [:index, :new]
  before_action :set_conversation_starters, only: [:new]

  def index
    if @version.blank?
      version = @conversation.messages.order(:created_at).last&.version
      if version
        redirect_to conversation_messages_path(params[:conversation_id], version: version), status: :see_other
      end
    end

    # Rows render pin, bookmark, and reaction state, so those ride along preloaded instead
    # of one query per row — same treatment the sidebar nav scopes give toggle state.
    @messages = @conversation.messages.preload(:pins, :bookmarks, :reactions).for_conversation_version(@version)
    # Slack-style pins tab: the conversation's pinned messages in display order (message pins
    # carry no hand order). Scoped to the conversation through the association, so another
    # user's pins can never leak in — same Current.user scoping as the other toggles.
    @pinned_messages = @conversation.messages.pinned_for(Current.user).order(:index)
    @new_message = @assistant.messages.new(conversation: @conversation)
    @streaming_message = Message.where(
      content_text: [nil, ""],
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
      set_nav_collections
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

  def react
    @message.react!(params[:emoji], Current.user)
    head :no_content
  rescue ActiveRecord::RecordInvalid
    head :unprocessable_content
  end

  def unreact
    @message.unreact!(params[:emoji], Current.user)
    head :no_content
  end

  def pin
    @message.pin!(Current.user)
    render_message_pin
  end

  def unpin
    @message.unpin!(Current.user)
    render_message_pin
  end

  def bookmark
    @message.bookmark!(Current.user)
    render_message_bookmark
  end

  def unbookmark
    @message.unbookmark!(Current.user)
    render_message_bookmark
  end

  private

  # Message pins answer with two streams — the pinned-messages section (replaced whole, so its
  # hidden-when-empty state refreshes too) and the row's own pin button — so both land with no
  # reload. The picker already updates its chip optimistically, so react/unreact stay bare 204s.
  # Plain requests still answer 204.
  def render_message_pin
    @pinned_messages = @message.conversation.messages.pinned_for(Current.user).order(:index)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("pinned-messages", partial: "messages/pinned_messages"),
          turbo_stream.update("#{helpers.dom_id(@message)}-pin", partial: "messages/message_toggle_button", locals: { message: @message, type: :pin })
        ]
      end
      format.html { head :no_content }
    end
  end

  # Message bookmarks answer with one stream — the row's own bookmark button — since
  # bookmarks are per-message state with no section to refresh (unlike pins). Plain
  # requests still answer 204.
  def render_message_bookmark
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update("#{helpers.dom_id(@message)}-bookmark", partial: "messages/message_toggle_button", locals: { message: @message, type: :bookmark })
      end
      format.html { head :no_content }
    end
  end

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

  def set_nav_assistants
    @nav_assistants = Current.user.assistants.includes(language_model: :api_service).ordered
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
