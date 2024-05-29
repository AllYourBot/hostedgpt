class CreateCredentials < ActiveRecord::Migration[7.1]
  def change
    create_table :credentials do |t|
      t.references :user, null: false, foreign_key: true
      t.string :type
      t.jsonb :properties
      t.string :email
      t.string :password_digest
      t.timestamp :last_authenticated_at

      t.timestamps
    end
  end
end
