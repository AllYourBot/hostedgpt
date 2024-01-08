class MessagesController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :set_conversation
  before_action :set_message, only: %i[show edit update destroy]

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

    if @message.save
      redirect_to [@conversation, @message], notice: "Message was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @message.update(message_params)
      redirect_to [@conversation, @message], notice: "Message was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @message.destroy!
    redirect_to conversation_messages_url(@conversation), notice: "Message was successfully destroyed.", status: :see_other
  end

  private

  def set_conversation
    @conversation = Conversation.find(params[:conversation_id])
  end

  def set_message
    @message = @conversation.messages.find(params[:id])
  end

  def message_params
    params.require(:message).permit(:role, :content_text)
  end
end
