class Settings::ApplicationController < ApplicationController
  before_action :set_settings_menu
  helper_method :settings_menu_key

  layout "settings"

  private

  def settings_menu_key = controller_name.to_sym

  def redirect_or_render(saved, notice:, template:)
    if saved
      redirect_to yield, notice:, status: :see_other
    else
      render template, status: :unprocessable_content
    end
  end

  def set_settings_menu
    # controller_name => array of items
    @settings_menu = {
      people: {
  I18n.t("app.settings.people.menu.account") => edit_settings_person_path,
      },

      assistants: {
  I18n.t("app.settings.assistants.menu.index") => settings_assistants_path,
      },

      memories: {
  I18n.t("app.settings.memories.menu.title") => settings_memories_path,
      },

      connectors: {
  I18n.t("app.settings.connectors.menu.index") => settings_connectors_path,
      },

      language_models: {
  I18n.t("app.settings.language_models.menu.index") => settings_language_models_path,
      },

      api_services: {
  I18n.t("app.settings.api_services.menu.index") => settings_api_services_path,
      },
    }

    @settings_menu[:admin] = { I18n.t("app.admin.menu") => admin_users_path } if Current.user.admin?
  end
end
