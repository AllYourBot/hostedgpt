module User::Registerable
  extend ActiveSupport::Concern

  included do
    after_create :create_initial_assistant
  end

  private

  def create_initial_assistant
    assistant = assistants.create! name: "HostedGPT"
    conversations.create! title: "HostedGPT", assistant: assistant
  end
end
