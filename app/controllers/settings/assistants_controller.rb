class Settings::AssistantsController < Settings::ApplicationController
  before_action :set_assistant, only: [:edit, :update, :destroy]

  def new
    @assistant = Assistant.new
  end

  def edit
  end

  def create
    @assistant = Current.user.assistants.new(assistant_params)

    if @assistant.save
      redirect_to edit_settings_assistant_path(@assistant), notice: "Saved"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @assistant.update(assistant_params)
      redirect_to edit_settings_assistant_path(@assistant), notice: "Saved", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @assistant.destroy!
    redirect_to new_settings_assistant_url, notice: "Deleted", status: :see_other
  end

  private

  def set_assistant
    @assistant = Current.user.assistants.find(params[:id])
  end

  def assistant_params
    params.require(:assistant).permit(:name, :description, :instructions)
  end
end
