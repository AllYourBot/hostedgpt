class HomeController < ApplicationController
  def index
    if Current.user.present? || session[:user_id].present?
      render :show
    else
      render :index
    end
  end
end
