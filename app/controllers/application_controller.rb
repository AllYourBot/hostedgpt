class ApplicationController < ActionController::Base
  include Authenticate

  allow_unauthenticated_access only: [:launch]
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
    return head(:not_found) unless (jwt_secret_key = ENV['HOSTEDGPT_JWT_SECRET_KEY']).present?
    return head(:unauthorized) unless (jwt = params[:jwt]).present?

    claims = begin
      logger.debug "\n\n#{JWT.decode(jwt, jwt_secret_key, true, algorithm: 'HS256')&.first}\n\n"
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

    reset_session
    Current.reset

    unless credential = HttpHeaderCredential.find_by(auth_uid: claims['sub'])
      Person.transaction do
        user = User.create!(name: "Student User")
        Person.create!(personable: user, email: email)
        HttpHeaderCredential.create!(user: user, external_id: claims['sub'])
      rescue ActiveRecord::RecordNotUnique
      end
      credential = HttpHeaderCredential.find_by!(auth_uid: claims['sub'])
    end
    person = credential.user.person

    assistants = [
      ["GPT-4o", "gpt-4o"],
      ["GPT-4", "gpt-4-turbo"],
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

    login_as(person, credential: credential)

    render json: {
      assistants: assistants.map do |a|
        a.as_json(include: :language_model)
      end
    }
  end

  private

  def ensure_manual_login_allowed
    return if manual_login_allowed?
    head :not_found
  end

  def format_and_strip_all_but_first_valid_credential(h)
    # RAILSFIX: Rails form helpers handle the has_many of credentials by using a hash with the id of the hash being the object id
    # This should be fine except the rails update code with a deep has_many expects an array of hashes with an id key-value pair
    # This method does the conversion. I should patch rails to fix the bug because currently it creates instead of updating.

    first_cred = h.dig("personable_attributes", "credentials_attributes").to_a.first
    if first_cred && first_cred[1]["type"] == "PasswordCredential"
      h["personable_attributes"]["credentials_attributes"] = [ has_many_nested_param_to_hash(first_cred) ]
    else
      h["personable_attributes"]["credentials_attributes"] = []
    end
    # This gnarly logic formats the ultimate hash like this:
    # CREATE w/ PASSWORD:
    #   {"email"=>"keith@hostedgpt.com", "personable_type"=>"User", "personable_attributes"=>{"name"=>"John Doe", "credentials_attributes"=>[{"type"=>"PasswordCredential", "password"=>"secret"}]}}
    # CREATE but FORGOT PASSWORD:
    #   {"email"=>"keith@hostedgpt.com", "personable_type"=>"User", "personable_attributes"=>{"name"=>"John Doe", "credentials_attributes"=>[{"type"=>"PasswordCredential", "password"=>""}]}}
    # UPDATE w/ PASSWORD CHANGE:
    #   {"email"=>"keith@hostedgpt.com-2", "personable_attributes"=>{"first_name"=>"Keith-2", "last_name"=>"Schacht-2", "openai_key"=>"abc123-2", "credentials_attributes"=>[{"id"=>"96043068", "type"=>"PasswordCredential", "password"=>"secret2"}]}}
    # UPDATE w/ PASSWORD UN-CHANGED:
    #   {"email"=>"keith@hostedgpt.com-2", "personable_attributes"=>{"first_name"=>"Keith-2", "last_name"=>"Schacht-2", "openai_key"=>"abc123-2", "credentials_attributes"=>[{"id"=>"96043068", "type"=>"PasswordCredential", "password"=>""}]}}
    # UPDATE w/ NO PASSWORD:
    #   {"email"=>"keith@hostedgpt.com-2", "personable_attributes"=>{"id"=>"721687368", "first_name"=>"Keith-2", "last_name"=>"Schacht-2", "openai_key"=>"abc123-2", "credentials_attributes"=>[]}}
    h
  end

  def has_many_nested_param_to_hash(arr)
    id = arr.first.to_i
    hash = arr.second
    id == 0 ? hash : hash.merge("id" => id.to_s)
  end
end
