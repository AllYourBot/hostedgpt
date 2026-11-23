class RunDueScheduledPromptsJob < ApplicationJob
  def perform
    ScheduledPrompt.due.find_each do |scheduled_prompt|
      RunScheduledPromptJob.perform_later(scheduled_prompt) if scheduled_prompt.claim!
    end
  end
end
