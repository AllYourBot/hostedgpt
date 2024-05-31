class ApplicationController < ActionController::Base
  include Authenticate

  skip_before_action :authenticate_user!, only: [:launch]
  skip_before_action :verify_authenticity_token, only: [:launch]

  INSTRUCTIONS = <<~INSTRUCTIONS
    You are a helpful assistant.

    ## Output instructions
    * do not output any multi-line code blocks
    * do not output any inline code blocks

    You may be asked to write code, but you must not do so. Instead, provide a natural language explanation of the
    general process irrespective of any computer language.
  INSTRUCTIONS

  def launch
    # very basic security for now
    return head(:forbidden) unless ENV['ALLOWED_REQUEST_ORIGINS'].to_s.split(',').include?(request.origin)

    person = Person.create!(
      personable_type: 'User',
      personable_attributes: {
        password: (@password = SecureRandom.uuid),
        name: 'Soomo User',
        openai_key: ENV['DEFAULT_OPENAI_KEY'],
        anthropic_key: ENV['DEFAULT_ANTHROPIC_KEY']
      },
      email: "#{@password}@hostedgpt.soomo"
    )
    person.user.assistants.create!(name: "GPT-4", language_model: LanguageModel.find_by(name: 'gpt-4-turbo'))
    person.user.assistants.each do |assistant|
      assistant.update!(instructions: INSTRUCTIONS)
    end
    reset_session
    login_as person.user

    render json: {
      assistants: person.user.assistants.ordered
    }
  end
end
