class AssistantsController < ApplicationController
  before_action :set_nav_conversations
  before_action :set_nav_assistants

  def index
    unless Feature.assistants_page?
      best_assistant = @nav_assistants.first
      redirect_to new_assistant_message_path(best_assistant), status: :see_other
      return
    end
  end
end
