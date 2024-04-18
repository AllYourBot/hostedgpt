class MessagesController < ApplicationController
  include ActiveStorage::SetCurrent
  include HasConversationStarter

  before_action :set_version, only: [:index, :update]
  before_action :set_conversation, only: [:index]
  before_action :set_assistant, only: [:index, :new, :create]
  before_action :set_message, only: [:show, :edit, :update, :destroy]
  before_action :set_nav_conversations, only: [:index, :new]
  before_action :set_nav_assistants, only: [:index, :new]
  before_action :set_conversation_starters, only: [:new]

  def index
    @messages = @conversation.messages.for_conversation_version(@version)
    @new_message = @assistant.messages.new(conversation: @conversation)
    @streaming_message = Message.where(
      content_text: nil,
      cancelled_at: nil
    ).find_by(id: redis.get("conversation-#{@conversation.id}-latest-assistant_message-id"))
  end

  def show  # show & edit will be used when we make messages editable
  end

  def new
    @new_message = @assistant.messages.new
  end

  def edit
  end

  def create
    @message = @assistant.messages.new(message_params)

    if @message.save # remember, an extra assistant message is auto-created
      GetNextAIMessageJob.perform_later(
        @message.conversation.latest_message_for_version(@message.version).id,
        @assistant.id
      )
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
    if @message.update(message_params)
      GetNextAIMessageJob.perform_later(@message.id, @message.assistant.id) if @message.previous_changes.any?
      redirect_to conversation_messages_path(@message.conversation, version: @version || @message.version)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @conversation = @message.conversation
    @message.destroy!
    redirect_to conversation_messages_url(@conversation), notice: "Message was successfully destroyed.", status: :see_other
  end

  private

  def set_version
    @version = params[:version].presence&.to_i
  end

  def set_conversation
    @conversation = Current.user.conversations.find(params[:conversation_id])
  end

  def set_assistant
    @assistant = Current.user.assistants.find_by(id: params[:assistant_id])
    @assistant ||= @conversation.messages.for_conversation_version(@version).last.assistant
  end

  def set_message
    @message = Message.find(params[:id])
  end

  def set_nav_conversations
    @nav_conversations = Conversation.grouped_by_increasing_time_interval_for_user(Current.user)
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
      documents_attributes: [:file]
    )
    if modified_params.has_key?(:content_text) && modified_params[:content_text].blank? # when we rerequest the content_text: nil is mistakenly getting converted to ""
      modified_params[:content_text] = nil
    end
    modified_params
  end

  def redis
    RedisConnection.client
  end
end
