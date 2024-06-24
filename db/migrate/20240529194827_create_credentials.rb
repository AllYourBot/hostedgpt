class CreateCredentials < ActiveRecord::Migration[7.1]
  def change
    drop_table :authentications if table_exists?(:authentications)
    drop_table :credentials if table_exists?(:credentials)
    create_table :credentials do |t|
      t.references :user, null: false, foreign_key: true
      t.string :type
      t.string :password_digest
      t.string :external_id, comment: "Credential models will alias this for their purpose (e.g. Google and HTTP Header)"
      t.string :oauth_email
      t.string :oauth_token
      t.string :oauth_refresh_token
      t.jsonb :properties
      t.timestamp :last_authenticated_at

      t.timestamps
    end

    add_index :credentials, :external_id
  end
end
