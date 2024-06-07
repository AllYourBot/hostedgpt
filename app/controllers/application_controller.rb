class ApplicationController < ActionController::Base
  include Authenticate

  private

  def ensure_user_authentication_allowed
    if Feature.disabled?(:password_authentication) && Feature.disabled?(:google_authentication)
      head :not_found
    end
  end

  def strip_all_but_first_credential(h)
    first_cred = h["personable_attributes"]["credentials_attributes"].first
    h["personable_attributes"]["credentials_attributes"] =
      (first_cred.second["type"] == "PasswordCredential") && [first_cred].to_h
    h
  end
end
