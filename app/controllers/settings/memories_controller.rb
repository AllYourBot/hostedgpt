class Settings::MemoriesController < Settings::ApplicationController
  before_action :set_memory, only: :destroy

  def index
    @memories = Current.user.memories.includes(:message)
  end

  def destroy
    @memory.destroy!
    redirect_to settings_memories_url, notice: "Forgotten", status: :see_other
  end

  def destroy_all
    Current.user.memories.delete_all
    redirect_to settings_memories_url, notice: "Cleared memory", status: :see_other
  end

  private

  def set_memory
    @memory = Current.user.memories.find_by(id: params[:id])
  end
end
