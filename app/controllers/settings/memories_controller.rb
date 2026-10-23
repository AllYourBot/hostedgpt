class Settings::MemoriesController < Settings::ApplicationController
  before_action :set_memories, only: [:index, :create]
  before_action :set_memory, only: :destroy

  def index
    @memory = Memory.new
  end

  def create
    @memory = Current.user.memories.new(memory_params)

    redirect_or_render(@memory.save, notice: I18n.t("app.flashes.memories.remembered"), template: :index) { settings_memories_url }
  end

  def destroy
    @memory.destroy!
    redirect_to settings_memories_url, notice: I18n.t("app.flashes.memories.forgotten"), status: :see_other
  end

  def destroy_all
    Current.user.memories.delete_all
    redirect_to settings_memories_url, notice: I18n.t("app.flashes.memories.cleared"), status: :see_other
  end

  private

  def set_memories
    @memories = Current.user.memories.includes(:message)
  end

  def set_memory
    @memory = Current.user.memories.find_by(id: params[:id])
  end

  def memory_params
    params.require(:memory).permit(:detail)
  end
end
