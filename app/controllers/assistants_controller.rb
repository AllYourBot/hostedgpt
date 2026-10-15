class AssistantsController < ApplicationController
  before_action :set_nav_assistants
  before_action :set_nav_collections

  def index
    unless Feature.assistants_page? && !mobile_device?
      best_assistant = @nav_assistants.first
      redirect_to new_assistant_message_path(best_assistant), status: :see_other
      return
    end
  end

  def reorder
    scope_ids = Assistant.reorder_scope(Current.user).ordered.pluck(:id)
    posted = Reorderable.normalize_ids(params[:ids]) & scope_ids
    Assistant.reposition(Current.user, posted | (scope_ids - posted))
    head :no_content
  end
end
