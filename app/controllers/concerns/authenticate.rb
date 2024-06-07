module Authenticate
  extend ActiveSupport::Concern
  include BearerToken, HttpHeaderAuth

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

  def find_client_by_cookie
    Client.find_by(token: session_token) unless session_token.blank?
  end

  def login_as(user_or_person, credential:)
    client = find_or_create_client_for(user_or_person)
    client.authenticate_with! credential
    session_authenticate_with client
  end

  def find_or_create_client_for(user_or_person)
    Current.client || user_or_person.clients.create!(
      platform: :web,
      user_agent: "",
      ip_address: "",
      time_zone_offset_in_minutes: 0
    )
  end

  def session_token
    session[:client_token] || cookies.signed[:client_token]
  end

  def reset_authentication
    session.delete(:session_token)
    cookies.delete(:client_token)
    Current.reset
  end

  def session_authenticate_with(client)
    if Current.initialize_with(client: client)
      session[:client_token] = client.token
      cookies.signed.permanent[:client_token] = { value: client.token, httponly: true, same_site: :lax }
    end
  end

  def post_authenticating_url
    session.delete(:return_to_after_authenticating) || root_url
  end
end
