class PinsController < ApplicationController
  before_action :set_conversation

  def create
    @conversation.pin!
    redirect_back fallback_location: root_path, status: :see_other
  end

  def destroy
    @conversation.unpin!
    redirect_back fallback_location: root_path, status: :see_other
  end

  private

  # find (not find_by) so that someone else's conversation, or one that does not exist, is a 404.
  def set_conversation
    @conversation = Current.user.conversations.find(params[:conversation_id])
  end
end
