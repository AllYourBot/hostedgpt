class Settings::ApplicationController < ApplicationController
  layout "settings"
  before_action :set_settings_assistants

  private

  def set_settings_assistants
    settings_assistants = Current.user.assistants.ordered.map {
        |assistant| [ assistant, edit_settings_assistant_path(assistant) ]
      }
    @settings_assistants = settings_assistants[0,5]
    if settings_assistants.length > 5
      @hide_settings_assistants = settings_assistants[5, settings_assistants.length - 5]

      # If user is editing an "overflow assistant" don't collapse that section, keep it open from the start
      @open_hide_settings_assistants  = params[:controller] =='settings/assistants' &&
        params[:action] == 'edit' &&
        @hide_settings_assistants.map(&:first).map(&:id).include?(params[:id].to_i)
    end
  end
end
