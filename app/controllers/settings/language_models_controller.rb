class Settings::LanguageModelsController < Settings::ApplicationController
  before_action :set_users_language_model, only: [:edit, :update, :destroy]
  before_action :set_language_model, only: [:show]

  def index
    @language_models = LanguageModel.for_user(Current.user).order(updated_at: :desc)
  end

  def edit
  end

  def show
  end

  def new
    @language_model = LanguageModel.new
  end

  def create
    @language_model = Current.user.language_models.new(language_model_params)

    if @language_model.save
      redirect_to settings_language_models_path, notice: "Saved"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @language_model.update(language_model_params)
      redirect_to edit_settings_language_model_path(@language_model), notice: "Saved", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @language_model.destroy!
    redirect_to new_settings_language_model_url, notice: "Deleted", status: :see_other
  end

  private

  def set_users_language_model
    @language_model = Current.user.language_models.find_by(id: params[:id])
    if @language_model.nil?
      redirect_to new_settings_language_model_url, notice: "The Language Model could not be found", status: :see_other
    end
  end

  def set_language_model
    @language_model = LanguageModel.find_by(id: params[:id])
  end

  def language_model_params
    params.require(:language_model).permit(:api_name, :description, :supports_images, :api_service_id)
  end
end
