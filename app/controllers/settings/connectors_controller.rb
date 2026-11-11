class Settings::ConnectorsController < Settings::ApplicationController
  before_action :set_connector, only: [:edit, :update, :destroy]

  def index
    @connectors = Current.user.connectors.ordered
  end

  def new
    @connector = Connector.new
  end

  def create
    @connector = Current.user.connectors.new(connector_params)

    redirect_or_render(@connector.save_with_tools, notice: I18n.t("app.flashes.connectors.saved"), template: :new) { settings_connectors_path }
  end

  def edit
  end

  def update
    @connector.assign_attributes(connector_params)

    redirect_or_render(@connector.save_with_tools, notice: I18n.t("app.flashes.connectors.saved"), template: :edit) { settings_connectors_path }
  end

  def destroy
    @connector.destroy!
    redirect_to settings_connectors_path, notice: I18n.t("app.flashes.connectors.deleted"), status: :see_other
  end

  private

  def set_connector
    @connector = Current.user.connectors.find_by(id: params[:id])
    if @connector.nil?
      redirect_to settings_connectors_path, alert: I18n.t("app.flashes.connectors.not_found"), status: :see_other
    end
  end

  # The form never shows the saved token, so a blank token field means "keep the current one".
  def connector_params
    params.require(:connector).permit(:name, :url, :token, enabled_tool_names: []).tap do |permitted|
      permitted.delete(:token) if permitted[:token].blank?
    end
  end
end
