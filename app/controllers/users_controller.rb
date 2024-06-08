class UsersController < ApplicationController
  require_unauthenticated_access except: :update

  before_action :ensure_manual_authentication_allowed, only: [:new, :create]
  before_action :ensure_registration_allowed, only: [:new, :create]
  before_action :set_user, only: [:update]

  layout "public"

  def new
    @person = Person.new
    @person.personable = User.new

    prettify_flash_error_messages
  end

  def create
    @person = Person.new(person_params)

    if @person.save
      login_as(@person, credential: @person.user.password_credential)
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

  def ensure_registration_allowed
    if Feature.disabled?(:registration)
      head :not_found
    end
  end

  def set_user
    @user = Current.user if params[:id].to_i == Current.user.id
  end

  def prettify_flash_error_messages
    flash[:errors]&.each { |error| @person.errors.add(:base, error) }
  end

  def person_params
    h = params.require(:person).permit(:email, :personable_type, personable_attributes: [
      :name, credentials_attributes: [ :type, :password ]
    ]).to_h
    strip_all_but_first_credential(h)
  end

  def user_params
    params.require(:user).permit(preferences: [:nav_closed, :dark_mode])
  end
end
