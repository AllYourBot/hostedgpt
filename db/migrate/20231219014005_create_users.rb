class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.references :person, null: false, foreign_key: true
      t.string :password
      t.datetime :registered_at

      t.timestamps
    end
  end
end
