class Settings::LanguageModelsController < Settings::ApplicationController
  before_action :set_users_language_model, only: [:edit, :update, :destroy]
  before_action :set_system_language_model, only: [:show]

  def index
    @language_models = LanguageModel.for_user(Current.user).ordered
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
      redirect_to settings_language_models_path, notice: "Saved", status: :see_other
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @language_model.update(language_model_params)
      redirect_to settings_language_models_path, notice: "Saved", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def test
    @language_model = Current.user.language_models.find_by(id: params[:language_model_id])
    @answer = @language_model.test(params[:model])

    respond_to do |format|
      format.html { redirect_to settings_language_models_path, notice: "Tested: #{@answer}", status: :see_other }
      format.turbo_stream
    end
  end

  def destroy
    @language_model.deleted!
    redirect_to settings_language_models_path, notice: "Deleted", status: :see_other
  end

  private

  def set_users_language_model
    @language_model = Current.user.language_models.find_by(id: params[:id])
    if @language_model.nil?
      redirect_to settings_language_models_path, status: :see_other, alert: "The Language Model could not be found"
    end
  end

  def set_system_language_model
    @language_model = LanguageModel.where(user_id: nil).find_by(id: params[:id])
  end

  def language_model_params
    params.require(:language_model).permit(:api_name, :name, :best, :supports_images, :supports_tools, :api_service_id, :supports_system_message)
  end
end
