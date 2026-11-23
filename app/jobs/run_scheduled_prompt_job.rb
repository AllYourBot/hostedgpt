class RunScheduledPromptJob < ApplicationJob
  discard_on ActiveJob::DeserializationError # the prompt was deleted after it was claimed

  def perform(scheduled_prompt) = scheduled_prompt.run!
end
