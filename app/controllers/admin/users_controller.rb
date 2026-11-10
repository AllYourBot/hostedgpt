class Admin::UsersController < Admin::ApplicationController
  before_action :set_person, only: [:edit, :update, :destroy]

  def index
    @users = User.includes(:person).ordered
  end

  def new
    @person = Person.new(personable: User.new)
  end

  def create
    @person = Person.new(new_person_params)

    if @person.save
      redirect_to admin_users_path, notice: I18n.t("app.flashes.admin.users.created"), status: :see_other
    else
      @person.errors.delete(:personable)
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @person.update(person_params)
      redirect_to admin_users_path, notice: I18n.t("app.flashes.admin.users.saved"), status: :see_other
    else
      @person.errors.delete(:personable)
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    if @person.personable == Current.user
      redirect_to edit_admin_user_path(@person.personable), alert: I18n.t("app.flashes.admin.users.cannot_delete_self"), status: :see_other
    else
      @person.destroy!
      redirect_to admin_users_path, notice: I18n.t("app.flashes.admin.users.deleted"), status: :see_other
    end
  end

  private

  def set_person
    @person = User.find(params[:id]).person
  end

  def new_person_params
    attributes = user_attributes
    attributes << { credentials_attributes: [:password] } if Feature.password_authentication?

    params.require(:person).permit(:email, personable_attributes: attributes).tap do |permitted|
      permitted[:personable_type] = "User"
      permitted.dig(:personable_attributes, :credentials_attributes)&.each_value { it[:type] = "PasswordCredential" }
    end
  end

  def person_params
    attributes = user_attributes
    attributes << :new_password if Feature.password_authentication?

    params.require(:person).permit(:email, personable_attributes: attributes).tap do |permitted|
      permitted[:personable_attributes]&.merge!(id: @person.personable_id)
    end
  end

  def user_attributes
    attributes = [:first_name, :last_name, :dark_mode, :show_thinking, :ask_follow_ups, :provider_web_search]
    @person&.personable == Current.user ? attributes : attributes + [:admin]
  end
end
