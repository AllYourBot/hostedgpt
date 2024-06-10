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

    uuid = password = SecureRandom.uuid
    person = Person.create!(
      personable_type: 'User',
      personable_attributes: {
        name: 'Student User',
      },
      email: "#{uuid}@hostedgpt.soomo"
    )
    person.user.create_password_credential!(
      type: 'PasswordCredential',
      password: password
    )
    person.user.assistants.create!(name: "GPT-4", language_model: LanguageModel.find_by(name: 'gpt-4-turbo'))
    person.user.assistants.each do |assistant|
      assistant.update!(instructions: INSTRUCTIONS)
    end
    reset_session
    login_as(person, credential: person.user.password_credential)

    render json: {
      assistants: person.user.assistants.ordered.map do |a|
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
