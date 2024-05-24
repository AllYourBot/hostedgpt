module Authenticate
  extend ActiveSupport::Concern

  included do
    before_action :current_user
    helper_method :current_user
    before_action :authenticate_user!
  end

  def login_as(user)
    return if Feature.http_header_authentication?

    session[:current_user_id] = user.id
  end

  def current_user
    return Current.user unless Current.user.nil?

    if Feature.http_header_authentication?
      find_current_user_based_on_http_header
    else
      find_current_user_based_on_session
    end

    Current.user
  end

  def user_signed_in?
    current_user.present?
  end

  def authenticate_user!
    redirect_to login_path unless current_user
  end

  private

  def find_current_user_based_on_session
    Current.user = User.find_by(id: session[:current_user_id])
    Current.person = Current.user&.person
    Current.user = nil if Current.person.nil?
  end

  def find_current_user_based_on_http_header
    if Feature.registration?
      Current.user = User.find_or_create_by!(uid: request.headers[Setting.http_header_auth_uid]) do |user|
        user.create_person!(email: request.headers[Setting.http_header_auth_email])
        user.name = request.headers[Setting.authentication_http_header_name] || person.email
      end
    else
      Current.user = User.find_by(uid: request.headers[Setting.http_header_auth_uid])
    end
    Current.person = Current.user&.person
  end
end
