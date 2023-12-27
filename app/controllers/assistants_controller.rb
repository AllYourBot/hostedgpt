class AssistantsController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :set_assistant, only: %i[show edit update destroy]

  def index
    @assistants = Assistant.all
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
    params.require(:assistant).permit(:user_id, :model, :name, :description, :instructions, :tools)
  end
end
