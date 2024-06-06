class CreateCredentials < ActiveRecord::Migration[7.1]
  def change
    create_table :credentials do |t|
      t.references :user, null: false, foreign_key: true
      t.string :type
      t.string :google_email
      t.string :external_id
      t.string :password_digest
      t.jsonb :properties
      t.timestamp :last_authenticated_at

      t.timestamps
    end

    add_index :credentials, :external_id, unique: true
  end
end
