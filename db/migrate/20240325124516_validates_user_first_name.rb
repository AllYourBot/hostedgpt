class ValidatesUserFirstName < ActiveRecord::Migration[7.1]
  def up
    User.where(first_name: nil).update_all(first_name: "First")
    change_column_null :users, :first_name, false
  end

  def down
    change_column_null :users, :first_name, true
  end
end
