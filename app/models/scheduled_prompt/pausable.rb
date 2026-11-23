module ScheduledPrompt::Pausable
  extend ActiveSupport::Concern

  FAILURES_BEFORE_PAUSE = 3

  included do
    before_save :forget_failures, if: -> { enabled_changed?(to: true) }
  end

  def paused_for_failures? = !enabled? && consecutive_failures >= FAILURES_BEFORE_PAUSE

  def record_reply(message)
    return unless reply_to_the_prompt?(message)

    if message.failed?
      record_failure!
    elsif message.content_tool_calls.blank?
      update!(consecutive_failures: 0) unless consecutive_failures.zero?
    end
  end

  private

  def reply_to_the_prompt?(message)
    message.conversation.messages.user.where(index: 1...message.index).none?
  end

  def record_failure!
    increment!(:consecutive_failures)
    update!(enabled: false) if consecutive_failures >= FAILURES_BEFORE_PAUSE
  end

  def forget_failures
    self.consecutive_failures = 0
  end
end
