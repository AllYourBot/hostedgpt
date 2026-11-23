class Settings::ScheduledPromptsController < Settings::ApplicationController
  before_action :set_scheduled_prompt, only: [:edit, :update, :destroy, :run]

  def index
    @scheduled_prompts = Current.user.scheduled_prompts.ordered.includes(:assistant)
  end

  def new
    @scheduled_prompt = Current.user.scheduled_prompts.new(assistant: Current.user.assistants.ordered.first)
  end

  def create
    @scheduled_prompt = Current.user.scheduled_prompts.new(scheduled_prompt_params)

    redirect_or_render(@scheduled_prompt.save, notice: I18n.t("app.flashes.scheduled_prompts.saved"), template: :new) do
      settings_scheduled_prompts_path
    end
  end

  def edit
  end

  def update
    saved = @scheduled_prompt.update(scheduled_prompt_params)

    redirect_or_render(saved, notice: I18n.t("app.flashes.scheduled_prompts.saved"), template: :edit) do
      settings_scheduled_prompts_path
    end
  end

  def destroy
    @scheduled_prompt.destroy!
    redirect_to settings_scheduled_prompts_path, notice: I18n.t("app.flashes.scheduled_prompts.deleted"), status: :see_other
  end

  def run
    message = @scheduled_prompt.run!
    redirect_to conversation_messages_path(message.conversation, version: message.version), status: :see_other
  end

  private

  def set_scheduled_prompt
    @scheduled_prompt = Current.user.scheduled_prompts.find_by(id: params[:id])
    if @scheduled_prompt.nil?
      redirect_to settings_scheduled_prompts_path, alert: I18n.t("app.flashes.scheduled_prompts.not_found"), status: :see_other
    end
  end

  def scheduled_prompt_params
    params.require(:scheduled_prompt).permit(:assistant_id, :prompt, :schedule, :time_zone, :enabled)
  end
end
