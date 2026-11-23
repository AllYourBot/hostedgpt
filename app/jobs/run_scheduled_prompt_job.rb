class RunScheduledPromptJob < ApplicationJob
  discard_on ActiveJob::DeserializationError

  def perform(scheduled_prompt) = scheduled_prompt.run!
end
