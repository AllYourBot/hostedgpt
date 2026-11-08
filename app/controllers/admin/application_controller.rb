class Admin::ApplicationController < Settings::ApplicationController
  before_action :require_admin
  before_action :reject_api_requests

  private

  def settings_menu_key = :admin

  def require_admin
    head :not_found unless Current.user.admin?
  end

  # ApplicationController#default_render serializes every ivar for JSON requests,
  # which would hand an admin every user's decrypted API key.
  def reject_api_requests
    head :not_acceptable if api_request?
  end
end
