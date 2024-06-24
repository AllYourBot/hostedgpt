class Settings::MemoriesController < Settings::ApplicationController
  def index
    @memories = Current.user.memories.includes(:message)
  end

  def destroy
    Current.user.memories.delete_all
    redirect_to settings_memories_url, notice: "Cleared memory", status: :see_other
  end
end
