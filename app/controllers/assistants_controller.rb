class AssistantsController < ApplicationController
  before_action :set_assistant, only: [:show, :edit, :update, :destroy]

  def index
    assistant = Current.user.assistants.ordered.first
    redirect_to new_assistant_message_path(assistant)
  end

  def show
  end

  def new
    @assistant = Assistant.new
  end

  def edit
  end

  def create
    @assistant = Assistant.new(assistant_params)

    if @assistant.save
      redirect_to @assistant, notice: "Assistant was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @assistant.update(assistant_params)
      redirect_to @assistant, notice: "Assistant was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @assistant.destroy!
    redirect_to assistants_url, notice: "Assistant was successfully destroyed.", status: :see_other
  end

  private

  def set_assistant
    @assistant = Assistant.find(params[:id])
  end

  def assistant_params
    params.require(:assistant).permit(:user_id, :language_model_id, :name, :description, :instructions, :tools)
  end
end
