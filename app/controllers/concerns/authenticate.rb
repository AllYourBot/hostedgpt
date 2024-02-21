module Authenticate
  extend ActiveSupport::Concern

  included do
    before_action :current_user
    helper_method :current_user
    before_action :authenticate_user!
  end

  def login_as(user)
    session[:current_user_id] = user.id
  end

  def current_user
    Current.user ||= User.find_by(id: session[:current_user_id])
    Current.person ||= Current.user&.person
    Current.user = nil if Current.person.nil?

    Current.user
  end

  def user_signed_in?
    current_user.present?
  end

  def authenticate_user!
    redirect_to login_path unless current_user
  end
end
