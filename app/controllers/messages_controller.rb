class MessagesController < ApplicationController
  before_action :set_conversation, only: [:index]
  before_action :set_assistant, only: [:index, :new, :create]
  before_action :set_message, only: [:show, :edit, :update, :destroy]
  before_action :set_sidebar_conversations, only: [:index, :new]
  before_action :set_sidebar_assistants, only: [:index, :new]

  def index
    @messages = @conversation.messages.sorted
    @new_message = @assistant.messages.new(conversation: @conversation)
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

    if @message.save
      GetNextAIMessageJob.perform_later(@message.conversation.id, @assistant.id)

      redirect_to conversation_messages_path(@message.conversation)
    else
      # what's the right flow for a failed message create? it's not this, but hacking it so tests pass until we have a plan
      set_sidebar_conversations
      set_sidebar_assistants
      @new_message = @assistant.messages.new

      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @message.update(message_params)
      redirect_to @message, notice: "Message was successfully updated.", status: :see_other
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

  def set_conversation
    @conversation = Current.user.conversations.find(params[:conversation_id])
  end

  def set_assistant
    @assistant = Current.user.assistants.find_by(id: params[:assistant_id])
    @assistant ||= @conversation.assistant
  end

  def set_message
    @message = Message.find(params[:id])
  end

  def set_sidebar_conversations
    @sidebar_conversations = Conversation.grouped_by_increasing_time_interval_for_user(Current.user)
  end

  def set_sidebar_assistants
    @sidebar_assistants = Current.user.assistants.sorted
  end

  def message_params
    params.require(:message).permit(:conversation_id, :content_text, documents_attributes: [:file])
  end
end
