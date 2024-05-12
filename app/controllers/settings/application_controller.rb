class Settings::ApplicationController < ApplicationController
  layout "settings"
  before_action :set_settings_assistants

  private

  def set_settings_assistants
    settings_assistants = Current.user.assistants.ordered.map {
        |assistant| [ assistant, edit_settings_assistant_path(assistant) ]
      }
    if settings_assistants.length > Assistant::MAX_LIST_DISPLAY
      assistants_to_hide = settings_assistants[Assistant::MAX_LIST_DISPLAY, settings_assistants.length - Assistant::MAX_LIST_DISPLAY]
      # If user is editing an "overflow assistant" don't collapse that section, keep it open from the start
      @hide_settings_assistants_overflow = params[:controller] !='settings/assistants' ||
        params[:action] != 'edit' ||
        !assistants_to_hide.map(&:first).map(&:id).include?(params[:id].to_i)
    end
    @settings_menu = {assistants: settings_assistants.to_h,
      new_assistant: {'New Assistant': new_settings_assistant_path},
      people: {'Account': edit_settings_person_path}}
  end
end
