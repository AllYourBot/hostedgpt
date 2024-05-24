class ApplicationController < ActionController::Base
  include Authenticate

  skip_before_action :authenticate_user!, only: [:launch]
  skip_before_action :verify_authenticity_token
  after_action { response.headers.except! 'X-Frame-Options' }

  def launch
    # very basic security for now
    return head(:forbidden) unless request.origin.to_s =~ /webtexts/

    person = Person.create!(
      personable_type: 'User',
      personable_attributes: {
        password: (@password = SecureRandom.uuid),
        name: 'Soomo User',
        openai_key: ENV['SOOMO_OPENAI_KEY'],
        anthropic_key: ENV['SOOMO_ANTHROPIC_KEY']
      },
      email: "#{@password}@hostedgpt.soomo"
    )
    person.user.assistants.each do |assistant|
      assistant.update!(instructions: 'You are a helpful assistant')
    end
    reset_session
    login_as person.user

    render json: {
      assistants: person.user.assistants.ordered
    }
  end
end
