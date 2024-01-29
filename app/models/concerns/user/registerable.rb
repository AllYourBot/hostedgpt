module User::Registerable
  extend ActiveSupport::Concern

  included do
    after_create :create_initial_assistant
  end

  private

  def create_initial_assistant
    assistants.create! name: "GPT-4", pinned: true
    assistants.create! name: "GPT-3.5", pinned: false
  end
end
