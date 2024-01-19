class MessagesController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :set_conversation, only: [:index, :new, :create]
  before_action :set_message, only: [:show, :edit, :update, :destroy]

  def index
    @messages = @conversation.messages
  end

  def show
  end

  def new
    @message = @conversation.messages.build
  end

  def edit
  end

  def create
    @message = @conversation.messages.build(message_params)
    @message.role = :user

    if @message.save
      redirect_to @message.conversation, notice: "Message was successfully created."
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

  def set_conversation
    @conversation = Current.user.conversations.find(params[:conversation_id])
  end

  def set_message
    @message = Message.find(params[:id])
  end

  def message_params
    params.require(:message).permit(:content_text)
  end
end
