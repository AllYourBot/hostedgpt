class SessionsController < ApplicationController
  include Accessible

  before_action :find_user_for_password_authentication, only: :create, if: -> { Feature.password_authentication? && !omniauth_authenticaton_ongoing?}
  before_action :find_user_for_google_authentication, only: :create, if: -> { Feature.google_authentication? && omniauth_authenticaton_ongoing? }

  layout "public"

  def new
  end

  def create
    if omniauth_authenticaton_ongoing? || @user&.authenticate(params[:password])
      reset_session
      login_as @user
      redirect_to root_path
    else
      flash.now[:alert] = "Invalid email or password"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    Current.user = nil
    redirect_to login_path
  end

  private

  def omniauth_authenticaton_ongoing?
    request.env['omniauth.auth'].present?
  end

  def find_user_for_password_authentication
    return if params[:email].blank? && params[:password].blank?

    person = Person.find_by(email: params[:email])

    @user = person&.personable
  end

  def find_user_for_google_authentication
    auth = request.env['omniauth.auth']
    return if auth.blank?

    if Feature.registration?
      @user = User.find_or_create_by!(uid: auth[:uid]) do |user|
        user.first_name = auth[:info][:first_name],
        user.last_name = auth[:info][:last_name]
        user.create_person!(email: auth[:info][:email])
      end
    else
      @user = User.find_by!(uid: auth[:uid])
    end
  end
end
