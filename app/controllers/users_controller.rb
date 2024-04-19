class UsersController < ApplicationController
  include Accessible

  layout "public"

  before_action :ensure_registration, only: [:new, :create]
  before_action :set_user, only: [:update]

  def new
    @person = Person.new
    @person.personable = User.new
  end

  def create
    @person = Person.new(person_params)

    if @person.save
      reset_session
      login_as @person.user

      redirect_to root_path
    else
      @person.errors.delete :personable
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @user.update(user_params)
      Current.user.reload
      redirect_back fallback_location: root_path, status: :see_other
    else
      redirect_back fallback_location: root_path, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = Current.user if params[:id].to_i == Current.user.id
  end

  def person_params
    params.require(:person).permit(:email, :personable_type, personable_attributes: [
      :name, :password
    ])
  end

  def user_params
    params.require(:user).permit(preferences: [:nav_closed, :color_theme])
  end

  def ensure_registration
    redirect_to root_path unless Feature.enabled?(:registration)
  end
end
