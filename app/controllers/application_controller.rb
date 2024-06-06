class ApplicationController < ActionController::Base
  include Authenticate

  private

  def ensure_session_based_authentication_allowed
    if Feature.disabled?(:password_authentication) && Feature.disabled?(:google_authentication)
      head :not_found
    end
  end
end
