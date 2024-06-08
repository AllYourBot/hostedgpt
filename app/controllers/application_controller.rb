class ApplicationController < ActionController::Base
  include Authenticate

  private

  def ensure_manual_authentication_allowed
    return if manual_authentication_allowed?
    head :not_found
  end

  def strip_all_but_first_credential(h)
    first_cred = h.dig("personable_attributes", "credentials_attributes", 0)
    if first_cred
      h["personable_attributes"]["credentials_attributes"] =
        (first_cred.second["type"] == "PasswordCredential") && [first_cred].to_h
    end
    h
  end
end
