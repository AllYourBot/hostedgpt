module Accessible
  extend ActiveSupport::Concern

  included do
    skip_before_action :authenticate_user!, only: [:new, :create]
    before_action -> { redirect_to(root_path) }, if: :user_signed_in?, only: [:new, :create]
  end
end
