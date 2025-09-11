class Settings::ApplicationController < ApplicationController
  before_action :set_settings_menu

  layout "settings"

  private

  def set_settings_menu
    # controller_name => array of items
    @settings_menu = {
      people: {
  I18n.t("app.settings.people.menu.account") => edit_settings_person_path,
      },

      memories: {
  I18n.t("app.settings.memories.menu.title") => settings_memories_path,
      },

      assistants: Current.user.assistants.ordered.map {
        |assistant| [ assistant, edit_settings_assistant_path(assistant) ]
      }.to_h.merge({
  I18n.t("app.settings.assistants.menu.new") => new_settings_assistant_path
      }),

      language_models: {
  I18n.t("app.settings.language_models.menu.index") => settings_language_models_path,
      },

      api_services: {
  I18n.t("app.settings.api_services.menu.index") => settings_api_services_path,
      },
    }
  end
end
