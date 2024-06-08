module Authenticate
  extend ActiveSupport::Concern
  include LoginLogout
  include ByCookie, ByBearerToken, ByHttpHeader

  included do
    before_action :require_authentication
    helper_method :signed_in?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
      before_action :restore_authentication, **options
    end

    def require_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
      before_action :restore_authentication, :redirect_signed_in_user_to_root, **options
    end
  end

  private

  def signed_in?
    Current.user.present?
  end

  def require_authentication
    restore_authentication || request_authentication
  end

  def restore_authentication
    Current.initialize_with(client: find_client)
  end

  def request_authentication
    session[:return_to_after_authenticating] = request.url
    redirect_to login_url
  end

  def redirect_signed_in_user_to_root
    redirect_to root_url if signed_in?
  end

  def find_client
    find_client_by_cookie || find_client_by_http_header || find_client_by_bearer_token
  end

  def post_authenticating_url
    session.delete(:return_to_after_authenticating) || root_url
  end
end
