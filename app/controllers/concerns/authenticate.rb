module Authenticate
  extend ActiveSupport::Concern

  included do
    before_action :ensure_current_user
    before_action :authenticate_user!
  end

  def login_as(user)
    return if Feature.http_header_authentication?

    reset_session
    session[:current_user_id] = user.id
  end

  def ensure_current_user
    return Current.user unless Current.user.nil?

    if Feature.http_header_authentication?
      find_current_user_based_on_http_header
    else
      find_current_user_based_on_session
    end

    Current.user
  end

  def user_signed_in?
    ensure_current_user.present?
  end

  def authenticate_user!
    return if ensure_current_user

    if Feature.http_header_authentication?
      render plain: 'Unauthorized', status: :unauthorized
    else
      redirect_to login_path, notice: 'Please login to proceed'
    end
  end

  private

  def find_current_user_based_on_session
    Current.user = User.find_by(id: session[:current_user_id])
    Current.person = Current.user&.person
    Current.user = nil if Current.person.nil?
  end

  def find_current_user_based_on_http_header
    if request.headers[Setting.http_header_auth_uid].blank?
      Rails.logger.error "HTTP header #{Setting.http_header_auth_uid} is missing"
      Current.person = Current.user = nil
      return
    end

    Current.user = user_find_or_create_by_auth_uid
    Current.person = Current.user&.person
    Current.user = nil if Current.person.nil?
  end

  def user_find_or_create_by_auth_uid
    if Feature.registration?
      User.find_or_create_by!(auth_uid: request.headers[Setting.http_header_auth_uid]) do |user|
        user.build_person(email: request.headers[Setting.http_header_auth_email])
        user.name = request.headers[Setting.authentication_http_header_name] || person.email
      end
    else
      User.find_by(auth_uid: request.headers[Setting.http_header_auth_uid])
    end
  end
end
