class ApplicationController < ActionController::Base
  include Authenticate

  private

  def ensure_user_authentication_allowed
    if Feature.disabled?(:password_authentication) && Feature.disabled?(:google_authentication)
      head :not_found
    end
  end
end
