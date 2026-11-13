class Admin::APIServicesController < Admin::ApplicationController
  before_action :set_api_service, only: [:edit, :update, :destroy]

  def index
    @api_services = APIService.not_deleted.includes(user: :person).order(:user_id, :name)
  end

  def new
    @api_service = APIService.new
  end

  def create
    @api_service = APIService.new(api_service_params.merge(params.require(:api_service).permit(:user_id)))

    if @api_service.save
      redirect_to admin_api_services_path, notice: I18n.t("app.flashes.admin.api_services.created"), status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @api_service.update(api_service_params)
      redirect_to admin_api_services_path, notice: I18n.t("app.flashes.admin.api_services.saved"), status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @api_service.deleted!
    redirect_to admin_api_services_path, notice: I18n.t("app.flashes.admin.api_services.deleted"), status: :see_other
  end

  def sync_models
    result = LanguageModel::RefreshFromRubyLLM.new.call
    redirect_to admin_api_services_path, notice: models_synced_notice(result), status: :see_other
  rescue RubyLLM::ModelRegistryError => e
    redirect_to admin_api_services_path, alert: I18n.t("app.flashes.admin.api_services.sync_failed", error: e.message), status: :see_other
  end

  private

  def set_api_service
    @api_service = APIService.not_deleted.find(params[:id])
  end

  def models_synced_notice(result)
    notice = I18n.t("app.flashes.admin.api_services.models_synced", count: result.added_count)
    return notice if result.missing_provider_identities.empty?

    providers = result.missing_provider_identities.map { AIBackend::Policy.for_identity(it).display_name }
    "#{notice} #{I18n.t("app.flashes.admin.api_services.no_registry_models", providers: providers.join(", "))}"
  end

  # Admins never see another user's key, so a blank key field means "keep the current one".
  def api_service_params
    params.require(:api_service).permit(:name, :url, :token, :driver, :service_type).tap do |permitted|
      permitted.delete(:token) if permitted[:token].blank?
    end
  end
end
