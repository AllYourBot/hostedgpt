class CreateAuthentications < ActiveRecord::Migration[7.1]
  def change
    create_table :authentications do |t|
      t.references :user, null: false, foreign_key: true
      t.references :credential, null: false, foreign_key: true
      t.string :token
      t.timestamp :ended_at

      t.timestamps
    end
  end
end
