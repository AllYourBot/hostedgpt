class ApplicationController < ActionController::Base
  before_action :set_current_user
  before_action :authenticate_user!

  def authenticate_user!
    redirect_to login_path unless Current.user
  end

  def set_current_user
    if session[:user_id]
      Current.user = User.find_by(id: session[:user_id])
    else
      Current.user = nil
    end
  end
end
