class AssistantsController < ApplicationController
  def index
    assistant = Current.user.assistants.ordered.first
    redirect_to new_assistant_message_path(assistant)
  end
end
