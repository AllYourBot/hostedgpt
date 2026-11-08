class Toolbox::AskUser < Toolbox
  FUNCTION_NAME = "askuser_ask_user"

  describe :ask_user, <<~S
    Ask the user a multiple-choice question and wait for their answer before continuing.
    Use this when you need the user to choose between a few options (2-5) to give a good answer.
    Put the options in choices, each a short label; don't also list them in your reply.
    Their answer arrives as their next message.
  S

  def ask_user(question_s:, choices_a: [])
    raise ArgumentError, "question can't be blank" if question_s.blank?

    { message_to_user: question_s, choices: listed(choices_a).map { it.to_s.strip }.compact_blank.uniq }
  end

  private

  # Some models send a list parameter as a JSON string.
  def listed(choices)
    return Array(choices) unless choices.is_a?(String) && choices.lstrip.start_with?("[")

    Array(JSON.parse(choices))
  rescue JSON::ParserError
    [choices]
  end
end
