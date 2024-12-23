class Settings::APIServicesController < Settings::ApplicationController
  before_action :set_api_service, only: [:edit, :update, :destroy]

  def index
    @api_services = Current.user.api_services.ordered
  end

  def edit
  end

  def new
    @api_service = APIService.new
  end

  def create
    @api_service = Current.user.api_services.new(api_service_params)

    if @api_service.save
      redirect_to settings_api_services_path, notice: "Saved", status: :see_other
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @api_service.update(api_service_params)
      redirect_to settings_api_services_path, notice: "Saved", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def test
    @api_service = Current.user.api_services.find_by(id: params[:api_service_id])
    @answer = @api_service.test_api_service(params[:url], params[:token])

    respond_to do |format|
      format.html { redirect_to settings_api_services_path, notice: "Tested: #{@answer}", status: :see_other }
      format.turbo_stream
    end
  end

  def destroy
    @api_service.deleted!
    redirect_to settings_api_services_path, notice: "Deleted", status: :see_other
  end

  private

  def set_api_service
    @api_service = Current.user.api_services.find_by(id: params[:id])
    if @api_service.nil?
      redirect_to settings_api_services_path, alert: "The API Service could not be found", status: :see_other
    end
  end

  def api_service_params
    params.require(:api_service).permit(:name, :url, :token, :driver)
  end
end
