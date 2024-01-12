class Assistants::InstructionsController < ApplicationController
  before_action :set_assistant

  def edit
  end

  def update
    @assistant.update!(assistant_params)
    redirect_to @assistant, notice: "Instructions have been saved."
  end

  private

  def set_assistant
    @assistant = Assistant.find(params[:assistant_id])
  end

  def assistant_params
    params.require(:assistant).permit(:instructions)
  end
end
