class SetDefaultFirstName < ActiveRecord::Migration[7.1]
  def up
    User.where(first_name: "").or(User.where(first_name: nil)).update_all(first_name: "Profile")
  end
end
