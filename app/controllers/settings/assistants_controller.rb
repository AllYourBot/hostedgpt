class Settings::AssistantsController < Settings::ApplicationController
  before_action :set_assistant, only: [:edit, :update, :destroy]
  before_action :set_last_assistant, except: [:destroy]

  def new
    @assistant = Assistant.new
  end

  def edit
  end

  def create
    @assistant = Current.user.assistants.new(assistant_params)

    if @assistant.save
      redirect_to edit_settings_assistant_path(@assistant), notice: I18n.t("app.flashes.assistants.saved"), status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @assistant.update(assistant_params)
      redirect_to edit_settings_assistant_path(@assistant), notice: I18n.t("app.flashes.assistants.saved"), status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    if Current.user.assistants.count > 1 && @assistant.deleted!
      redirect_to new_settings_assistant_url, notice: I18n.t("app.flashes.assistants.deleted"), status: :see_other
    else
      redirect_to new_settings_assistant_url, alert: I18n.t("app.flashes.assistants.last_delete_error"), status: :see_other
    end
  end

  private

  def set_assistant
    @assistant = Current.user.assistants.find_by(id: params[:id])
    if @assistant.nil?
      redirect_to new_settings_assistant_url, notice: I18n.t("app.flashes.assistants.deleted_full"), status: :see_other
    end
  end

  def set_last_assistant
    @last_assistant = Current.user.assistants.count <= 1
  end

  def assistant_params
    params.require(:assistant).permit(:name, :slug, :description, :instructions, :language_model_id)
  end
end
