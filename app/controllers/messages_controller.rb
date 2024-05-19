class MessagesController < ApplicationController
  include ActiveStorage::SetCurrent
  include HasConversationStarter

  before_action :set_version,               only: [:index, :update]
  before_action :set_conversation,          only: [:index]
  before_action :set_assistant,             only: [:index, :new, :edit, :create]
  before_action :set_message,               only: [:show, :edit, :update]
  before_action :set_nav_conversations,     only: [:index, :new]
  before_action :set_nav_assistants,        only: [:index, :new]
  before_action :set_conversation_starters, only: [:new]

  def index
    if @version.blank?
      version = @conversation.messages.order(:created_at).last&.version
      redirect_to conversation_messages_path(
        params[:conversation_id],
        version: version
      ) if version
    end

    @messages = @conversation.messages.for_conversation_version(@version)
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
      GetNextAIMessageJob.perform_later(current_user.id, after_create_assistant_reply.id, @assistant.id)
      redirect_to conversation_messages_path(@message.conversation, version: @message.version)
    else
      # what's the right flow for a failed message create? it's not this, but hacking it so tests pass until we have a plan
      set_nav_conversations
      set_nav_assistants
      @new_message = @assistant.messages.new

      render :new, status: :unprocessable_entity
    end
  end

  def update
    # Clicking edit beneath a message actually submits to create and not here. This action is only used for next/prev conversation.
    # In order to force a morph we PATCH to here and redirect.
    @message.allow_deleted_assistant = true # disable that validation
    if @message.update(version_navigate_message_params)
      redirect_to conversation_messages_path(@message.conversation, version: @version || @message.version)
    else
      render :edit, status: :unprocessable_entity
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
    @assistant ||= @conversation.latest_message_for_version(@version).assistant
  end

  def set_message
    @message = Message.find(params[:id])
  end

  def set_nav_conversations
    @nav_conversations = Conversation.grouped_by_increasing_time_interval_for_user(Current.user)
  end

  def set_nav_assistants
    @nav_assistants = Current.user.assistants.ordered
    @hide_settings_assistants_overflow = @nav_assistants.length > Assistant::MAX_LIST_DISPLAY &&
      @nav_assistants.index(@assistant) <= Assistant::MAX_LIST_DISPLAY-1
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
      documents_attributes: [:file]
    )
    if modified_params.has_key?(:content_text) && modified_params[:content_text].blank?
      modified_params[:content_text] = nil # nil and "" have different meanings
    end
    modified_params
  end

  def version_navigate_message_params
    params.require(:message).permit(:conversation_id, :version)
  end
end
