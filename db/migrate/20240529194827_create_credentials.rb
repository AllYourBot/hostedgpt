class CreateCredentials < ActiveRecord::Migration[7.1]
  def change
    create_table :credentials do |t|
      t.references :user, null: false, foreign_key: true
      t.string :type
      t.string :password_digest
      t.string :oauth_id
      t.string :oauth_email
      t.string :oauth_token
      t.string :oauth_refresh_token
      t.jsonb :properties
      t.timestamp :last_authenticated_at

      t.timestamps
    end

    add_index :credentials, :oauth_id
  end
end
