class Settings::APIServicesController < Settings::ApplicationController
  before_action :set_api_service, only: [:show, :edit, :update, :destroy]

  def index
    @api_services = APIService.all.order(updated_at: :desc)
  end

  def edit
  end

  def show
  end

  def new
    @api_service = APIService.new
  end

  def create
    @api_service = Current.user.api_services.new(api_service_params)

    if @api_service.save
      redirect_to settings_api_services_path, notice: "Saved"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @api_service.update(api_service_params)
      redirect_to edit_settings_api_service_path(@api_service), notice: "Saved", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @api_service.destroy!
    redirect_to new_settings_api_service_url, notice: "Deleted", status: :see_other
  end

  private

  def set_users_api_service
    @api_service = Current.user.api_services.find_by(id: params[:id])
    if @api_service.nil?
      redirect_to new_settings_api_service_url, notice: "The API Service was deleted", status: :see_other
    end
  end

  def set_api_service
    @api_service = APIService.find_by(id: params[:id])
  end

  def api_service_params
    params.require(:api_service).permit(:name, :url, :access_token)
  end
end
