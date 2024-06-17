class SoomoLaunchesController < ApplicationController

  allow_unauthenticated_access

  INSTRUCTIONS = <<~INSTRUCTIONS
    You are a helpful assistant.

    ## Output instructions
    * do not output any multi-line code blocks
    * do not output any inline code blocks

    You may be asked to write code, but you must not do so. Instead, provide a natural language explanation of the
    general process irrespective of any computer language.
  INSTRUCTIONS

  def create
    return head(:forbidden) unless ENV['ALLOWED_REQUEST_ORIGINS'].to_s.split(',').include?(request.origin)
    return head(:not_found) unless (jwt_secret_key = ENV['HOSTEDGPT_JWT_SECRET_KEY']).present?
    return head(:unauthorized) unless (jwt = params[:jwt]).present?

    claims = begin
      JWT.decode(jwt, jwt_secret_key, true, algorithm: 'HS256')&.first
    rescue JWT::ExpiredSignature
      logger.warn "JWT expired: #{jwt}"
      return head(:unauthorized)
    rescue JWT::DecodeError
      logger.warn "JWT invalid: #{jwt}"
      return head(:unauthorized)
    end
    email = "#{claims['sub']}@hostedgpt.soomo"
    course_id, element_family_id = claims['cid'], claims['fid']

    unless credential = HttpHeaderCredential.find_by(auth_uid: claims['sub'])
      Person.transaction do
        user = User.create!(name: "Student User")
        person = Person.create!(personable: user, email: email)
        credential = HttpHeaderCredential.create!(user: user, external_id: claims['sub'])
      rescue ActiveRecord::RecordNotUnique
      end
      credential = HttpHeaderCredential.find_by!(auth_uid: claims['sub'])
    end
    person = credential.user.person

    Person.transaction do
      person = Person.lock.find(person.id)
      unless person.clients.api.authenticated.exists?
        client = person.clients.create!(platform: 'api')
        client.authenticate_with!(credential)
      end
    end

    client = person.clients.api.authenticated.last

    assistants = [
      ["GPT-4o", "gpt-4o"],
      ["GPT-3.5", "gpt-3.5-turbo"],
      ["Claude 3 Opus", "claude-3-opus-20240229"],
      ["Claude 3 Sonnet", "claude-3-sonnet-20240229"]
    ].map do |(assistant_name, model_name)|
      person.user.assistants.create!(
        name: assistant_name,
        description: "#{course_id}:#{element_family_id}:#{Time.now.utc.iso8601}",
        instructions: INSTRUCTIONS,
        language_model: LanguageModel.find_by(name: model_name)
      )
    end

    render json: {
      api_key: client.bearer_token,
      assistants: assistants.map do |a|
        a.as_json(include: :language_model)
      end
    }
  end

end
