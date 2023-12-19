class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :password_digest
      t.datetime :registered_at, default: -> { "CURRENT_TIMESTAMP" }
    end
  end
end
