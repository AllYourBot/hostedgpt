module Authenticate
  extend ActiveSupport::Concern
  include LoginLogout
  include ByCookie, ByHttpHeader

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
    if manual_authentication_allowed?
      redirect_to login_url
    else
      render plain: 'Unauthorized', status: :unauthorized
    end
  end

  def redirect_signed_in_user_to_root
    redirect_to root_url if signed_in?
  end

  def find_client
    find_client_by_cookie || find_client_by_http_header
  end

  def post_authenticating_url
    session.delete(:return_to_after_authenticating) || root_url
  end
end
