class ApplicationController < ActionController::Base
  before_action :set_current_user
  before_action :authenticate_user!

  def authenticate_user!
    redirect_to login_path unless Current.user
  end

  def set_current_user
    Current.user = if session[:user_id]
      User.find_by(id: session[:user_id])
    end
  end
end
