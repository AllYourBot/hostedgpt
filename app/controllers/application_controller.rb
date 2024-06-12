class ApplicationController < ActionController::Base
  include Authenticate

  before_action :set_system_ivars

  def default_render
    if api_request?
      json_payload = user_defined_ivars.map { |i| [ i.to_s[1..], instance_variable_get(i) ] }.to_h
      render json: json_payload, status: :ok
    else
      super
    end
  end

  private

  def set_system_ivars
    @system_ivars = public_ivars
  end

  def public_ivars
    instance_variables.select { |i| !i.to_s.starts_with?('@_') }
  end

  def api_request?
    request.format.json?
  end

  def user_defined_ivars
    public_ivars - @system_ivars
  end

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
