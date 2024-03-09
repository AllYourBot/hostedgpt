module User::Registerable
  extend ActiveSupport::Concern

  included do
    after_create :create_initial_assistants
  end

  private

  def create_initial_assistants
    assistants.create! name: "GPT-4",   model: "gpt-4-vision-preview",  images: true
    assistants.create! name: "GPT-3.5", model: "gpt-3.5-turbo-0125",    images: false
    assistants.create! name: "Claude 3 Opus", model: "claude-3-opus-20240229", images: true
    assistants.create! name: "Claude 3 Sonnet", model: "claude-3-sonnet-20240229", images: true
  end
end
