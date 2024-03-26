class ValidatesUserFirstName < ActiveRecord::Migration[7.1]
  def change
    change_column_null :users, :first_name, false
  end
end
