class MessagesController < ApplicationController
  skip_before_action :authenticate_user! # TODO: finish authentication

  before_action :set_conversation, only: [:index]
  before_action :set_assistant, only: [:index, :new, :create]
  before_action :set_message, only: [:show, :edit, :update, :destroy]

  def index
    @messages = @conversation.messages
    @new_message = @assistant.messages.new(conversation: @conversation)
  end

  def show
  end

  def new
    @new_message = @assistant.messages.new
  end

  def edit
  end

  def create
    @message = @assistant.messages.new(message_params)

    if @message.save
      redirect_to @message, notice: "Message was successfully created."
    else
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

  def set_assistant
    @assistant = Current.user.assistants.find(params[:assistant_id])
  end

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

  def message_params
    params.require(:message).permit(:conversation_id, :content_text)
  end
end
